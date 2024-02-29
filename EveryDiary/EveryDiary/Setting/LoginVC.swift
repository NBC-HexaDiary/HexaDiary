//
//  LoginVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/28/24.
//

import UIKit
import CryptoKit
import AuthenticationServices

import SnapKit
import FirebaseAuth
import Firebase
import GoogleSignIn

class LoginVC: UIViewController {
    
    fileprivate var currentNonce: String?
    
    private lazy var backgroundImage : UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "View.Background2")
        return image
    }()
    
    private lazy var signGoogleButton : UIButton = {
        let btn = UIButton()
        btn.setImage(.signInGoogle, for: .normal)
        btn.addTarget(self, action: #selector(tapGoogleLoginButton), for: .touchUpInside)
        return btn
    }()
    
    private lazy var signAppleButton : UIButton = {
        let button = UIButton()
        button.setImage(.signinApple, for: .normal)
        button.addTarget(self, action: #selector(tapAppleLoginButton), for: .touchUpInside)
        return button
    }()
    
    @objc func tapAppleLoginButton() {
        startSignInWithAppleFlow()
    }
    
    @objc func tapGoogleLoginButton() {
        handleGIDSignIn()
    }
    
    //MARK: - Google로 로그인 및 Firebase 인증
    private func handleGIDSignIn() {
        // 버튼 클릭 시, 인증
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            guard error == nil else { return }
            
            // 인증을 해도 계정 등록 절차가 필요하다
            // 구글 인증 토큰 받고 -> 사용자 정보 토큰 생성
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString
            else { return }
            
            let email = user.profile?.email
            let fullName = user.profile?.name
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            // 사용자 정보 토큰 -> Firebase에 로그인 프로세스
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                print("Firebase login 성공 \(String(describing: email)),\(String(describing: fullName))")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

// MARK: - Apple로 로그인 및 Firebase 인증
extension LoginVC {
    // 로그인 요청마다 임의의 문자열 'nonce' 생성
    // 'nonce'는 앱의 인증 요청에 대한 응답 -> ID 토큰이 명시적으로 부여되었는지 확인하는 데 사용
    // 재전송 공격을 방지하기 위한 함수
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    // 'nonce'의 SHA256 해시를 전송하면 Apple은 이에 대한 응답으로 원래의 값 전달
    // Firebase는 원래의 nonce를 해싱하고 Apple에서 전달한 값과 비교하여 응답을 검증
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // Apple의 응답을 처리하는 대리자 클래스와 nonce의 SHA256 해시를 요청에 포함하는 것으로 Apple의 로그인 과정 시작
    @available(iOS 13, *)
    private func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

// delegate를 구현하여 Apple의 응답을 처리.
// 로그인에 성공했으면 해시되지 않는 nonce가 포함된 Apple의 응답에서 ID 토큰을 이용하여 Firebase에 인증
@available(iOS 13.0, *)
extension LoginVC : ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email ?? "이메일 없음"
            // Initialize a Firebase credential, including the user's full name.
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error.localizedDescription)
                    return
                }
                print("Firebase 로그인 성공 \(idTokenString),\(String(describing: fullName)),\(email)")
                self.navigationController?.popViewController(animated: true)
                // User is signed in to Firebase with Apple.
                // ...
            }
        }
    }
    
    // 로그인이 제대로 되지 않았을 경우, Error 발생
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
    
}


//MARK: - Views & Layouts
extension LoginVC {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubViewsLoginVC()
        autoLayoutLoginVC()
    }
    
    private func addSubViewsLoginVC() {
        view.addSubview(backgroundImage)
        view.sendSubviewToBack(backgroundImage)
        view.addSubview(signGoogleButton)
        view.addSubview(signAppleButton)
    }
    
    private func autoLayoutLoginVC() {
        signGoogleButton.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.centerY.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.width.equalTo(view.safeAreaLayoutGuide).offset(-32)
            make.height.equalTo(60)
        }
        backgroundImage.snp.makeConstraints { make in
            make.edges.equalTo(view).inset(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        }
        signAppleButton.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.centerY.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.width.equalTo(view.safeAreaLayoutGuide).offset(-32)
            make.height.equalTo(60)
        }
    }
    
}
