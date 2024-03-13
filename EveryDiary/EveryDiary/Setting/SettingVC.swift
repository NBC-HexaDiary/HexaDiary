//
//  SettingVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit
import CryptoKit
import AuthenticationServices

import SnapKit
import FirebaseAuth
import Firebase
import GoogleSignIn

class SettingVC: UIViewController {
        
    private var loginStatus: Bool = false
    
    private var dataSource = [CellModel]()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SettingCell.self, forCellReuseIdentifier: SettingCell.id)
        tableView.register(ProfileCell.self, forCellReuseIdentifier: ProfileCell.id)
        tableView.register(SignOutCell.self, forCellReuseIdentifier: SignOutCell.id)
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .mainBackground
        tableView.separatorStyle = .none
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviewsSettingVC()
        autoLayoutSettingVC()
        }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBar()
        observeAuthState()
        tableView.selectRow(at: .none,
                            animated: true,
                            scrollPosition: .top)
    }
    
    private func addSubviewsSettingVC() {
        view.backgroundColor = .mainBackground
        view.addSubview(tableView)
    }
    
    private func autoLayoutSettingVC() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(10)
        }
    }
    
    @objc func didTapLoginButton() {
        let loginVC = LoginVC()
        loginVC.modalPresentationStyle = .automatic
        self.present(loginVC, animated: true)
    }
    
    @objc func tapLogoutButton() {
        signOutAlert()
    }
        
    private func setNavigationBar() {
        navigationItem.title = "설정"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "설정", style: .plain, target: nil, action: nil)
        navigationController?.navigationBar.tintColor = .mainTheme
    }
}

// MARK: - 사용자의 로그인 상태 유무 감지 & 로그아웃 기능
extension SettingVC {
    
    // 로그인 상태 별 TableView의 구성
    private func refresh() {
        if let currentUser = Auth.auth().currentUser {
            if currentUser.isEmailVerified == false {
                self.dataSource = [
                    .profileItem(email: "일기를 저장하려면 로그인해주세요", name: "Guest", image: "profile", isLoggedIn: false),
                    .settingItem(title: "알림", iconImage: "notification", number: 1),
                    .settingItem(title: "잠금", iconImage: "lock", number: 2),
                    .signOutItem(title: "로그 아웃", iconImage: "logoutRed", number: 1, isLoggedIn: false),
                    .signOutItem(title: "회원 탈퇴", iconImage: "trash", number: 2, isLoggedIn: false)
                ]
            } else if currentUser.isEmailVerified == true {
                self.dataSource = [
                    .profileItem(email: currentUser.email ?? "일기를 저장하려면 로그인해주세요", name: currentUser.displayName ?? "Error", image: "profile", isLoggedIn: true),
                    .settingItem(title: "알림", iconImage: "notification", number: 1),
                    .settingItem(title: "잠금", iconImage: "lock", number: 2),
                    .signOutItem(title: "로그 아웃", iconImage: "logoutRed", number: 1, isLoggedIn: true),
                    .signOutItem(title: "회원 탈퇴", iconImage: "trash", number: 2, isLoggedIn: true)
                ]
            }
        } else {
            self.dataSource = [
                .profileItem(email: "일기를 저장하려면 로그인해주세요", name: "손님", image: "profile", isLoggedIn: false),
                .settingItem(title: "알림", iconImage: "notification", number: 1),
                .settingItem(title: "잠금", iconImage: "lock", number: 2),
                .signOutItem(title: "로그 아웃", iconImage: "logoutRed", number: 1, isLoggedIn: false),
                .signOutItem(title: "회원 탈퇴", iconImage: "trash", number: 2, isLoggedIn: false)
            ]
        }
        tableView.reloadData()
    }
    
    // Firebase 인증 상태 감지 메서드
     private func observeAuthState() {
         Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
             guard let self = self else { return }
             if let user = user {
                 // 사용자가 로그인되어 있음을 알림
                 if user.isEmailVerified == false {
                     // 사용자가 익명 계정으로 로그인 된 경우
                     // 로그인 버튼을 활성화 후 데이터 새로고침
                     self.loginStatus = false
                 } else if user.isEmailVerified == true {
                     // 사용자가 소셜 계정으로 로그인 된 경우
                     // 로그인 버튼을 비활성화 후 데이터 새로고침
                     self.loginStatus = true
                 }
                 self.refresh()
             } else {
                 // 사용자가 로그인되어 있지 않다면 loginStatus을 false로 설정하고 데이터를 새로고침
                 self.loginStatus = false
                 self.refresh()
             }
         }
     }
    
    // 사용자 로그아웃 기능
    private func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            if Auth.auth().currentUser == nil {
                print("로그아웃 성공!")
            } else {
                print("로그아웃 실패!")
            }
        } catch let signOutError as NSError {
            print("Error Signing out:  %@", signOutError)
        }

    }
    
    // 사용자 로그아웃 재차 확인
    private func signOutAlert() {
        let alertController = UIAlertController(title: "알림", message: "로그아웃 하시겠습니까?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default) { (_) in
            self.signOut()
            self.signOutConfirmAlert()
            NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
        }
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // 로그아웃 시, 나오는 알림창
    private func signOutConfirmAlert() {
        let okAlert = UIAlertController(title: "확인", message: "로그아웃이 완료되었습니다.", preferredStyle: .alert)
        let okClick = UIAlertAction(title: "확인", style: .default) { _ in
        }
        okAlert.addAction(okClick)
            
        self.present(okAlert, animated: true, completion: nil)
    }
}

// MARK: - Firebase 사용자 회원탈퇴 & Apple 탈퇴
extension SettingVC {
    // Firebase에서 사용자 데이터 삭제
    func deleteUserDataFromFirebase() {
        let firebaseAuth = Auth.auth()
        guard let currentUser = firebaseAuth.currentUser else {
            print("No user is currently signed in.")
            return
        }
        
        // 사용자 계정 삭제
        currentUser.delete { error in
            if let error = error {
                print("Error deleting user from Firebase: \(error.localizedDescription)")
            } else {
                print("User successfully deleted from Firebase.")
                // 사용자 계정에 저장되있던 모든 데이터 삭제
                DiaryManager.shared.deleteUserData(for: currentUser.uid)
            }
        }
    }

    // 사용자에게 Firebase 회원탈퇴, Apple or Google 소셜아이디 등록 탈퇴하도록 안내하는 메시지 표시
    func showDeleteAccountMessage() {
        let alert = UIAlertController(title: "회원 탈퇴하시겠습니까?", message: "일기에 저장된 모든 내용이 삭제되며  복구가 불가능해집니다. \n 그래도 진행하시겠습니까?", preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "회원 탈퇴", style: .destructive) { _ in
            self.deleteUserDataFromApple()
            self.showDeleteAccountConfirmAlert()
            NotificationCenter.default.post(name: .loginstatusChanged, object: nil)
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // 회원 탈퇴 시, 나오는 알림 창
    func showDeleteAccountConfirmAlert() {
        let confirmAlert = UIAlertController(title: "회원 탈퇴", message: "회원 탈퇴가 완료되었습니다.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "확인", style: .default)
        
        confirmAlert.addAction(confirmAction)
        
        present(confirmAlert, animated: true, completion: nil)
    }
    
    // Apple 계정 탈퇴
    func deleteUserDataFromApple() {
      let token = UserDefaults.standard.string(forKey: "refreshToken")
     
      if let token = token {
          let url = URL(string: "https://us-central1-everydiary-a9c5e.cloudfunctions.net/revokeToken?refresh_token=\(token)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com")!
     
          let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
              if let error = error {
                  print("Error:", error.localizedDescription)
                  return
              }
              
              // HTTP 응답 코드 확인
              if let httpResponse = response as? HTTPURLResponse {
                  print("HTTP Status Code:", httpResponse.statusCode)
              }
              
              // 응답 데이터 확인
              if let data = data, let utf8Text = String(data: data, encoding: .utf8) {
                  print("Response Data:", utf8Text)
              }
          }
          task.resume()
      }
        // Firebase 회원 탈퇴
        deleteUserDataFromFirebase()
      // 마지막으로 Firebase 로그아웃
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

// MARK: - TableView 구성
extension SettingVC : UITableViewDelegate, UITableViewDataSource {
    // TableView의 Cell 갯수는 datasource의 조건에 따라 달라진다
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    // 각 cell 별 커스텀
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.dataSource[indexPath.row] {
            
        case let .profileItem(email, name, image, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: ProfileCell.id, for: indexPath) as! ProfileCell
            cell.prapare(email: email, name: name, image: image, isLoggedIn: loginStatus)
            cell.backgroundColor = .mainBackground
            cell.loginButton.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
            return cell
            
        case let .settingItem(title, iconImage, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingCell.id, for: indexPath) as! SettingCell
            cell.prepare(title: title, iconImage: iconImage)
            cell.backgroundColor = .mainBackground
            return cell
            
        case let .signOutItem(title, iconImage, _, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: SignOutCell.id, for: indexPath) as! SignOutCell
            cell.prepare(title: title, iconImage: iconImage, isLoggedIn: loginStatus)
            cell.backgroundColor = .mainBackground
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = dataSource[indexPath.row]
        
        switch selectedItem {
        case .settingItem(_, _, let number):
            switch number {
            case 1:
                let notificationVC = NotificationVC()
                navigationController?.pushViewController(notificationVC, animated: true)
            case 2:
                let lockVC = LockVC()
                navigationController?.pushViewController(lockVC, animated: true)
            default:
                print("error")
            }
        case .signOutItem(_, _, let number, _):
            switch number {
            case 1:
                signOutAlert()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 0.5초 후에 실행
                    tableView.deselectRow(at: indexPath, animated: true)
                }
                print("로그아웃")
            case 2:
                print("회원 탈퇴")
                showDeleteAccountMessage()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 0.5초 후에 실행
                    tableView.deselectRow(at: indexPath, animated: true)
                }
            default:
                print("Error")
            }
        default:
            print("No Any Action")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = dataSource[indexPath.row]
            switch item {
            case .profileItem(_, _, _, _):
                return 133
            case .settingItem(_, _, _):
                return 100
            case .signOutItem(_, _, _, isLoggedIn: false):
                return 0
            default:
                return 100
            }
    }
}

