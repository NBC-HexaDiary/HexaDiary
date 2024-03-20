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
                    // Face ID 인증 성공
                    completion(true)
                } else {
                    // Face ID 인증 실패
                    completion(false)
                }
            }
        } else {
            // Face ID를 사용할 수 없는 경우
            completion(false)
        }
    }
}
