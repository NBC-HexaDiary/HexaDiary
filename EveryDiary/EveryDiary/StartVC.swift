////
////  StartVC.swift
////  EveryDiary
////
////  Created by Dahlia on 3/13/24.
////
import UIKit
import CryptoKit
import AuthenticationServices

import SnapKit
import FirebaseAuth
import Firebase
import GoogleSignIn

#Preview {
    StartVC()
}

class StartVC: UIViewController {
    fileprivate var currentNonce: String?
    
    private lazy var backgroundImage : UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "View.Background2")
        return image
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
    
    lazy var startButton : UIButton = {
        var config = UIButton.Configuration.plain()
        let button = UIButton(configuration: config)
        button.backgroundColor = UIColor.mainTheme
        button.setTitle("게스트로 시작", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(tabStartButton), for: .touchUpInside)
        //        button.alpha = 0.8
        return button
    }()
    
    @objc private func tabStartButton() {
        DiaryManager.shared.authenticateAnonymouslyIfNeeded { error in
            if let error = error {
                print("Error authenticating anonymously: \(error)")
                return
            }
        }
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        showMainScreen()
    }
    
    func showMainScreen() {
        DispatchQueue.main.async { [weak self] in
            guard let navigationController = self?.navigationController else { return }
            let diaryListVC = DiaryListVC()
            diaryListVC.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(diaryListVC, animated: true)
        }
    }
    
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
            
            // 익명 사용자인지 확인
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                // 익명 사용자를 영구 계정으로 전환
                print("Firebase login 성공 \(String(describing: email)),\(String(describing: fullName))")
                
                currentUser.link(with: credential) { authResult, error in
                    if let error = error {
                        print("익명 사용자를 영구 계정으로 전환하는 중 오류 발생: \(error.localizedDescription)")
                        return
                    }
                    let changeRequest = currentUser.createProfileChangeRequest()
                    changeRequest.displayName = fullName
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("Error updating user profile: \(error)")
                        }
                        print("익명 사용자를 영구 계정으로 전환 성공")
                        print("Firebase login 성공 \(String(describing: email)),\(String(describing: fullName))")
                        NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            } else {
                // 익명 사용자가 아닌 경우에는 바로 로그인
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("자격 증명으로 로그인 중 오류 발생: \(error.localizedDescription)")
                        return
                    }
                    print("Firebase login 성공 \(String(describing: email)),\(String(describing: fullName))")
                    NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}

// MARK: - Views & Layouts
extension StartVC {
    
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
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            view.addSubview(startButton)
        } else {
            showMainScreen()
        }
    }
    
    private func autoLayoutLoginVC() {
        signGoogleButton.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.centerY.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.width.equalTo(view.safeAreaLayoutGuide).offset(-32)
            make.height.equalTo(60)
        }
        
        startButton.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.top.equalTo(signGoogleButton.snp.bottom).offset(20)
            make.width.equalTo(view.safeAreaLayoutGuide).offset(-250)
            make.height.equalTo(40)
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

// MARK: - Apple로 로그인 및 Firebase 인증
extension StartVC {
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
extension StartVC : ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
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
            // Firebase에 로그인
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                currentUser.link(with: credential) { authResult, error in
                    if let error = error {
                        print("익명 사용자를 영구 계정으로 전환하는 중 오류 발생: \(error.localizedDescription)")
                        return
                    }
                    let changeRequest = currentUser.createProfileChangeRequest()
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
                // 익명 사용자가 아닌 경우에는 바로 로그인
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("자격 증명으로 로그인 중 오류 발생: \(error.localizedDescription)")
                        return
                    }
                    NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
                    self.dismiss(animated: true, completion: nil)
                }
            }
            print("identityToken: \(idTokenString)")
            if let email = appleIDCredential.email {
                print("Email: \(email)")
            } else {
                print("Email not provided")
            }
            
            if let fullName = appleIDCredential.fullName {
                let displayName = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")"
                print("Full Name: \(displayName)")
            } else {
                print("Full Name not provided")
            }
            NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
            self.dismiss(animated: true, completion: nil)
            // Apple 로그인을 통한 Firebase 로그인 성공 & SettingVC로 자동 전환
            
            
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
