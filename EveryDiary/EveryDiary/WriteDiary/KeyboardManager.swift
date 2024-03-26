//
//  KeyboardManager.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/20/24.
//

import UIKit
import SnapKit

// 키보드의 높이를 계산하여 contents를 담고있는 ScrollView의 높이를 조정.
class KeyboardManager {
    private weak var scrollView: UIScrollView?
    private var bottomConstraint: Constraint
    
    init(scrollView: UIScrollView, bottomConstraint: Constraint, viewController: UIViewController) {
        self.scrollView = scrollView
        self.bottomConstraint = bottomConstraint
    }
    
    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
                let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }
        
        let bottomPadding = window.safeAreaInsets.bottom
        // 키보드의 높이
        let keyboardHeight = keyboardSize.height - bottomPadding
        
        adjustScrollViewForKeyboardAppearance(with: keyboardHeight, show: true)
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        adjustScrollViewForKeyboardAppearance(with: 0, show: false)
    }
    
    private func adjustScrollViewForKeyboardAppearance(with keyboardHeight: CGFloat, show: Bool) {
        if show {
            let adjustmentHeight = show ? keyboardHeight : 0
            bottomConstraint.update(inset: adjustmentHeight)
        } else {
            bottomConstraint.update(inset: 0)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.scrollView?.layoutIfNeeded()
        }
    }
}
