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

#Preview{
    LoginVC()
}

class LoginVC: UIViewController {
    
    fileprivate var currentNonce: String?
    
    private lazy var topLabel : UILabel = {
        let label = UILabel()
        label.text = "마음 놓고"
        label.font = UIFont(name: "SFProDisplay-Bold", size: 50)
        label.textAlignment = .left
        label.textColor = UIColor(named: "mainCell")
        return label
    }()
    
    private lazy var bottomLabel : UILabel = {
        let label = UILabel()
        label.text = "일기 쓰자"
        label.font = UIFont(name: "SFProDisplay-Bold", size: 50)
        label.textAlignment = .left
        label.textColor = UIColor(named: "subBackground")
        return label
    }()
    
    private lazy var signGoogleButton : UIButton = {
        let signGoogleButton = UIButton()
        signGoogleButton.setImage(.signInGoogle, for: .normal)
        signGoogleButton.addTarget(self, action: #selector(tapGoogleLoginButton), for: .touchUpInside)
        return signGoogleButton
    }()
    
    private lazy var signAppleButton : UIButton = {
        let signAppleButton = UIButton()
        signAppleButton.setImage(.signinApple, for: .normal)
        signAppleButton.addTarget(self, action: #selector(tapAppleLoginButton), for: .touchUpInside)
        return signAppleButton
    }()
    
    private lazy var closeButton : UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(systemName:"xmark"), for: .normal)
        closeButton.sizeToFit()
        closeButton.tintColor = .mainCell
        closeButton.addTarget(self, action: #selector(tapCloseButton), for: .touchUpInside)
        return closeButton
    }()
    
    @objc func tapAppleLoginButton() {
        startSignInWithAppleFlow()
    }
    
    @objc func tapGoogleLoginButton() {
        handleGIDSignIn()
    }
    
    @objc func tapCloseButton() {
        dismiss(animated: true, completion: nil)
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
            
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                print("Firebase login 성공 \(String(describing: email)),\(String(describing: fullName))")
                
                currentUser.link(with: credential) { authResult, error in
                    if let error = error {
                        print("익명 사용자를 영구 계정으로 전환하는 중 오류 발생: \(error.localizedDescription)")
                        
                        Auth.auth().currentUser?.delete { error in
                            if let error = error {
                                print("Error deleting user from Firebase: \(error.localizedDescription)")
                            } else {
                                print("User successfully deleted from Firebase.")
                                DiaryManager.shared.deleteUserData(for: currentUser.uid)
                            }
                        }
                        
                        Auth.auth().signIn(with: credential) { authResult, error in
                            if let error = error {
                                print("로그인 중 오류 발생: \(error.localizedDescription)")
                                return
                            }
                            print("로그인 성공")
                            let changeRequest = currentUser.createProfileChangeRequest()
                            changeRequest.displayName = fullName
                            changeRequest.commitChanges { error in
                                if let error = error {
                                    print("Error updating user profile: \(error)")
                                }
                                print("사용자 프로필 업데이트 완료")
                                NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                        return
                    }
                    // 유저링크를 성공적으로 완료한 경우
                    let changeRequest = currentUser.createProfileChangeRequest()
                    changeRequest.displayName = fullName
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("Error updating user profile: \(error)")
                        }
                        print("익명 사용자를 영구 계정으로 전환 성공")
                        NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            } else {
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        // 로그인 중 오류가 발생한 경우
                        print("로그인 중 오류 발생: \(error.localizedDescription)")
                        return
                    }
                    // 익명 사용자가 아닌 경우에는 이미 병합된 계정이거나 일반 계정입니다.
                    print("비로그인 상태에서 로그인 시도 성공")
                    NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}

// MARK: - Views & Layouts
extension LoginVC {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubViewsLoginVC()
        autoLayoutLoginVC()
    }
    
    private func addSubViewsLoginVC() {
        view.addSubview(signGoogleButton)
        view.addSubview(signAppleButton)
        view.addSubview(closeButton)
        view.addSubview(topLabel)
        view.addSubview(bottomLabel)
        view.backgroundColor = .loginBackground
    }
    
    private func autoLayoutLoginVC() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.right.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.width.height.equalTo(25)
        }
        closeButton.imageView?.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        signGoogleButton.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.width.equalTo(view.safeAreaLayoutGuide).offset(-50)
            make.height.equalTo(60)
        }
        signAppleButton.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.top.equalTo(signGoogleButton.snp.bottom).offset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(50)
            make.width.equalTo(view.safeAreaLayoutGuide).offset(-50)
            make.height.equalTo(60)
        }
        topLabel.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.width.equalTo(view.safeAreaLayoutGuide).offset(-50)
        }
        bottomLabel.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.centerY.equalTo(view.safeAreaLayoutGuide).offset(-120)
            make.width.equalTo(view.safeAreaLayoutGuide).offset(-100)
            make.top.equalTo(topLabel.snp.bottom).offset(5)
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

// MARK: - Delegate 패턴을 이용한 Apple 로그인 처리
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
            
            // identityToken 가져오기
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            
            // 가져온 identityToken, String 타입 변환
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            // 변환한 identityToken을 Firebase 로그인 인증에 맞게 할당
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)

            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                
                currentUser.link(with: credential) { authResult, error in
                    if let error = error {
                        print("익명 사용자를 영구 계정으로 전환하는 중 오류 발생: \(error.localizedDescription)")
                    }
                    let changeRequest = currentUser.createProfileChangeRequest()
                    if let fullName = appleIDCredential.fullName {
                        changeRequest.displayName = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")"
                    }
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("Error updating user profile: \(error)")
                        }
                        print("익명 사용자를 영구 계정으로 전환 성공")
                        NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
                
                Auth.auth().currentUser?.delete { error in
                    if let error = error {
                        print("Error deleting user from Firebase: \(error.localizedDescription)")
                    } else {
                        print("User successfully deleted from Firebase.")
                        DiaryManager.shared.deleteUserData(for: currentUser.uid)
                    }
                }
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("로그인 중 오류 발생: \(error.localizedDescription)")
                        return
                    }
                    NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                print("이미 병합된 계정이거나 일반 계정입니다.")
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("로그인 중 오류 발생: \(error.localizedDescription)")
                        return
                    }
                    NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
                    self.dismiss(animated: true, completion: nil)
                }
            }
            
            // 사용자의 authorizationCode를 로그인 시 미리 가져온다. 회원 탈퇴 시, 필요하기 때문이다.
            if let authorizationCode = appleIDCredential.authorizationCode, let codeString = String(data: authorizationCode, encoding: .utf8) {
                let url = URL(string: "https://us-central1-everydiary-a9c5e.cloudfunctions.net/getRefreshToken?code=\(codeString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com")!
                let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                    if let data = data {
                        let refreshToken = String(data: data, encoding: .utf8) ?? ""
                        print(refreshToken)
                        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
                        UserDefaults.standard.synchronize()
                    }
                }
                task.resume()
            }
        }
    }
    
    // 로그인이 제대로 되지 않았을 경우, Error 발생
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("로그인 실패 - \(error.localizedDescription)")
    }
}

