//
//  KeyboardManager.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/20/24.
//

import UIKit
import SnapKit

class KeyboardManager {
    private weak var scrollView: UIScrollView?
    private var bottomConstraint: Constraint
    private var safeAreaBottomInset: CGFloat = 0
    
    init(scrollView: UIScrollView, bottomConstraint: Constraint, viewController: UIViewController) {
        self.scrollView = scrollView
        self.bottomConstraint = bottomConstraint
        self.safeAreaBottomInset = viewController.view.safeAreaInsets.bottom
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
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            adjustScrollViewForKeyboardAppearance(with: keyboardHeight, show: true)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        adjustScrollViewForKeyboardAppearance(with: 0, show: false)
    }
    
    private func adjustScrollViewForKeyboardAppearance(with keyboardHeight: CGFloat, show: Bool) {
        if show {
            let adjustmentHeight = keyboardHeight - safeAreaBottomInset
            bottomConstraint.update(inset: adjustmentHeight)
        } else {
            bottomConstraint.update(inset: 0)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.scrollView?.layoutIfNeeded()
        }
    }
}
