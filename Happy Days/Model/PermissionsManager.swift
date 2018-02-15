//
//  PermissionsManager.swift
//  Happy Days
//
//  Created by Артур Азаров on 15.02.2018.
//  Copyright © 2018 Артур Азаров. All rights reserved.
//

import Photos
import AVFoundation
import Speech

enum PermissionError: String {
    case photos
    case recording
    case transcription
    case notAuthorized
    
    private func errorMessage(about item: String) -> String {
        return "\(item) permission was declined; please enable it in settings then tap Continue again."
    }
}

extension PermissionError: Error {}

extension PermissionError: LocalizedError {
    var errorDescription: String? {
        return errorMessage(about: self.rawValue.uppercased())
    }
}

typealias CompletionHandler = (PermissionError?) -> ()
struct PermissionsManager {
    
    // MARK: - Methods
 
    func requestPermissions(completion: CompletionHandler?) {
        
        // MARK: -
        func requestPhotosPermissions() {
            PHPhotoLibrary.requestAuthorization { authStatus in
                if authStatus == .authorized {
                    requestRecordPermissions()
                } else {
                    completion?(PermissionError.photos)
                }
            }
        }
        
        // MARK: -
        
        func requestRecordPermissions() {
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                if allowed {
                    requestTranscribePermissions()
                } else {
                    completion?(PermissionError.recording)
                }
            }
        }
        
        // MARK: -
        
        func requestTranscribePermissions() {
            SFSpeechRecognizer.requestAuthorization { authStatus in
                if authStatus == .authorized {
                    completion?(nil)
                } else {
                    completion?(PermissionError.transcription)
                }
            }
        }
        requestPhotosPermissions()
    }
    
    func checkPermissions(completion: CompletionHandler?) {
        let photoAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == . authorized
        let authorized = photoAuthorized && recordingAuthorized && transcribeAuthorized
        if !authorized { completion?(PermissionError.notAuthorized)}
    }
}
