//
//  TemporaryAlert.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/25/24.
//

import UIKit

class TemporaryAlert {
    // 사용자에게 일시적인 메세지를 보여줄 때 사용하는 메서드
    static func presentTemporaryMessage(with title: String, message: String, interval: Double, for viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        viewController.present(alert, animated: true, completion: nil)
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)})
    }
}
