//
//  LoginVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/28/24.
//

import UIKit

import SnapKit
import FirebaseAuth
import Firebase
import GoogleSignIn

class LoginVC: UIViewController {
    
    private lazy var backgroundImage : UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "View.Background2")
        return image
    }()
    
    private lazy var signgoogleButton : GIDSignInButton = {
        let btn = GIDSignInButton()
        btn.colorScheme = .light
        btn.style = .wide
        btn.addTarget(self, action: #selector(handleGIDSignInButton), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubViewsLoginVC()
        autoLayoutLoginVC()
    }
    
    private func addSubViewsLoginVC() {
        view.addSubview(backgroundImage)
        view.sendSubviewToBack(backgroundImage)
        view.addSubview(signgoogleButton)
    }
    
    private func autoLayoutLoginVC() {
        signgoogleButton.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
        }
        backgroundImage.snp.makeConstraints { make in
            make.edges.equalTo(view).inset(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        }
    }
    
    @objc func handleGIDSignInButton() {
        // 버튼 클릭 시, 인증
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            guard error == nil else { return }
            
            // 인증을 해도 계정 등록 절차가 필요하다
            // 구글 인증 토큰 받고 -> 사용자 정보 토큰 생성 -> 파이어베이스 인증 등록
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString
            else { return }
            
            let emailAddress = user.profile?.email
            let fullName = user.profile?.name
            let profilePicUrl = user.profile?.imageURL(withDimension: 320)
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { result, error in
                //사용자 등록 후 처리할 코드
            }
        }
    }
}
