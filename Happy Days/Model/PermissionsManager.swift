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
    case photos = "Photos"
    case recording = "Recording"
    case transcription = "Transcription"
    
    private func errorMessage(about item: String) -> String {
        return "\(item) permission was declined; please enable it in settings then tap Continue again."
    }
}

extension PermissionError: Error {}

extension PermissionError: LocalizedError {
    var errorDescription: String? {
        return errorMessage(about: self.rawValue)
    }
}

struct PermissionsManager {
    
    // MARK: - Methods
    
    func requestPermissions(errorHandler: @escaping (_ error: PermissionError) -> (), completionHandler: @escaping  () -> ()) {
        
        // MARK: -
        func requestPhotosPermissions() {
            PHPhotoLibrary.requestAuthorization { authStatus in
                if authStatus == .authorized {
                    requestRecordPermissions()
                } else {
                    errorHandler(.photos)
                }
            }
        }
        
        // MARK: -
        
        func requestRecordPermissions() {
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                if allowed {
                    requestTranscribePermissions()
                } else {
                    errorHandler(.recording)
                }
            }
        }
        
        // MARK: -
        
        func requestTranscribePermissions() {
            SFSpeechRecognizer.requestAuthorization { authStatus in
                if authStatus == .authorized {
                    completionHandler()
                } else {
                    errorHandler(.transcription)
                }
            }
        }
        requestPhotosPermissions()
    }
}
