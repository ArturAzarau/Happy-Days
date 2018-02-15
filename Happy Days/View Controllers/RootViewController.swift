//
//  RootViewController.swift
//  Happy Days
//
//  Created by Артур Азаров on 14.02.2018.
//  Copyright © 2018 Артур Азаров. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

private enum ReuseIdentifier {
    static let cell = "Memory"
    static let header = "Header"
}

final class RootViewController: UICollectionViewController {
    
    // MARK: - Properties
    
    var memories = [URL]()
    var activeMemory: URL!
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL!
    var audioPlayer: AVAudioPlayer?
    
    // MARK: - Life cycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        checkPermissions()
    }

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMemories()
        recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
    }

    // MARK: - Methods
    
    private func checkPermissions() {
        let photoAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == . authorized
        
        let authorized = photoAuthorized && recordingAuthorized && transcribeAuthorized
        
        if !authorized {
            let vc = UIStoryboard(name: "Permissions", bundle: Bundle.main).instantiateViewController(withIdentifier: "PermissionsVC")
            navigationController?.present(vc, animated: true)
        }
    }
    
    // MARK: -
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    // MARK: -
    
    private func loadMemories() {
        memories.removeAll()
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else { return }
        
        for file in files {
            let fileName = file.lastPathComponent
            if fileName.hasSuffix(".thumb") {
                let noExtension = fileName.replacingOccurrences(of: ".thumb", with: "")
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                memories.append(memoryPath)
            }
        }
        collectionView?.reloadSections(IndexSet(integer: 1))
    }
    
    // MARK: -
    
    private func saveNewMemory(image: UIImage) {
        let memoryName = "memory- \(Date().timeIntervalSince1970)"
        let imageName = memoryName + ".jpg"
        let thumbnailImage = memoryName + ".thumb"
        
        do {
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            if let jpegData = UIImageJPEGRepresentation(image, 80) {
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            
            if let thumbnail = resize(image: image, to: 200) {
                let imagePath = getDocumentsDirectory().appendingPathComponent(thumbnailImage)
                if let jpegData = UIImageJPEGRepresentation(thumbnail, 80) {
                    try jpegData.write(to: imagePath, options: [.atomicWrite])
                }
            }
        } catch {
            print("Failed to save to disk")
        }
    }
    
    // MARK: -
    
    @objc
    private func memoryLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let cell = sender.view as! MemoryCell
            if let index = collectionView?.indexPath(for: cell) {
                activeMemory = memories[index.row]
                recordMemory()
            }
        } else if sender.state == .ended {
            finishRecording(success: true)
        }
    }
    
    // MARK: -
    
    private func recordMemory() {
        audioPlayer?.stop()
        collectionView?.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try recordingSession.setActive(true)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch let error {
            print("Failed to record: \(error.localizedDescription)")
            finishRecording(success: false)
        }
    }
    
    // MARK: -
    
    private func finishRecording(success: Bool) {
        collectionView?.backgroundColor = UIColor.darkGray
        
        audioRecorder?.stop()
        
        if success {
            do {
                let memoryAudioURL = activeMemory.appendingPathExtension("m4a")
                let fm = FileManager.default
                
                if fm.fileExists(atPath: memoryAudioURL.path) {
                    try fm.removeItem(at: memoryAudioURL)
                }
                
                try fm.moveItem(at: recordingURL, to: memoryAudioURL)
                
                transcribeAudio(memory: activeMemory)
            } catch let error {
                print("Failure finishing recording: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: -
    
    private func transcribeAudio(memory: URL) {
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        
        recognizer?.recognitionTask(with: request, resultHandler: { [unowned self] (result, error) in
            guard let result = result else {
                print("There was an error: \(error!.localizedDescription)")
                return
            }
            
            if result.isFinal {
                let text = result.bestTranscription.formattedString
                do {
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    print("Failed to save transcription.")
                }
            }
        })
    }
    
    // MARK: -
    
    private func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        let scale = width / image.size.width
        let height = image.size.height * scale
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height) , false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // MARK: - Actions
    
    @IBAction func addTapped(_ sender: UIBarButtonItem) {
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true)
    }
    
    // MARK: - Collection view data source
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    // MARK: -
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        } else {
            return memories.count
        }
    }
    
    // MARK: -
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifier.cell, for: indexPath) as! MemoryCell
        
        let memory = memories[indexPath.row]
        let imageName = thumbnailURL(for: memory).path
        let image = UIImage(contentsOfFile: imageName)
        cell.imageView.image = image
        
        if cell.gestureRecognizers == nil {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(memoryLongPress))
            recognizer.minimumPressDuration = 0.25
            cell.addGestureRecognizer(recognizer)
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 3
            cell.layer.cornerRadius = 10
        }
        return cell
    }
    
    // MARK: -
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ReuseIdentifier.header, for: indexPath)
    }
    
    // MARK: - Collection view delegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = memories[indexPath.row]
        let fm = FileManager.default
        
        do {
            let audioName = audioURL(for: memory)
            let transcriptionName = transcriptionURL(for: memory)
            
            if fm.fileExists(atPath: audioName.path) {
                audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                audioPlayer?.play()
            }
            
            if fm.fileExists(atPath: transcriptionName.path) {
                let contents = try String(contentsOf: transcriptionName)
                print(contents)
            }
        } catch {
            print("Error loading audio")
        }
    }
    
    // MARK: - Helper methods
    
    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    // MARK: -
    
    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    // MARK: -
    
    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    // MARK: -
    
    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }
}

extension RootViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        
        if let possibleImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            saveNewMemory(image: possibleImage)
            loadMemories()
        }
    }
}

extension RootViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize.zero
        } else {
            return CGSize(width: 0, height: 50)
        }
    }
}

extension RootViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}
extension RootViewController: UINavigationControllerDelegate {}
