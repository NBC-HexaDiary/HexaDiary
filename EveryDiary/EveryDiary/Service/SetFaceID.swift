//
//  SetFaceID.swift
//  EveryDiary
//
//  Created by Dahlia on 2/28/24.
//
import LocalAuthentication
import UIKit

class BiometricsAuth {    
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "인증이 필요합니다."
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if success {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        } else {
            completion(false, error)
        }
    }
}
