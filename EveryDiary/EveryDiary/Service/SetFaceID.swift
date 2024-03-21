//
//  SetFaceID.swift
//  EveryDiary
//
//  Created by Dahlia on 2/28/24.
//
import UIKit
import LocalAuthentication

class BiometricsAuth {
    
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate with Face ID"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        } else {
            completion(false)
        }
    }
}
