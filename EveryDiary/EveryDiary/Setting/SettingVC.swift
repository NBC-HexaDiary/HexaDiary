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

class SettingVC: UIViewController, ProfileCellDelegate {
    
    private var dataSource = [CellModel]()
    
    private lazy var logoutButton: UIButton = {
        var config = UIButton.Configuration.plain()
        let logoutBTN = UIButton(configuration: config)
        logoutBTN.setImage(.logout, for: .normal)
        logoutBTN.tintColor = .red
        logoutBTN.addTarget(self, action: #selector(tapLogoutButton), for: .touchUpInside)
        return logoutBTN
    }()
    
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SettingCell.self, forCellReuseIdentifier: SettingCell.id)
        tableView.register(ProfileCell.self, forCellReuseIdentifier: ProfileCell.id)
        tableView.register(SignOutCell.self, forCellReuseIdentifier: SignOutCell.id)
        tableView.rowHeight = 100
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .mainBackground
        tableView.separatorStyle = .none
        return tableView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviewsSettingVC()
        autoLayoutSettingVC()
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.selectRow(at: .none,
                            animated: true,
                            scrollPosition: .top)
    }
    
    private func refresh() {
        self.dataSource = [
            .profileItem(email: "fast129@naver.com", name: "고은성", image: "profile"),
            .settingItem(title: "알림", iconImage: "notification",number: 1),
            .settingItem(title: "잠금", iconImage: "lock", number: 2),
            .signOutItem(title: "로그 아웃", iconImage: "logoutRed", number: 1),
            .signOutItem(title: "회원 탈퇴", iconImage: "trash", number: 2)
        ]
        self.tableView.reloadData()
    }
    
    func didTapLoginButton() {
        let loginVC = LoginVC()
        loginVC.modalPresentationStyle = .automatic
        self.present(loginVC, animated: true)
    }
    
    @objc func tapLogoutButton() {
        signOutAlert()
    }
        
    //사용자 로그아웃 기능
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
    
    private func signOutAlert() {
        let alertController = UIAlertController(title: "알림", message: "로그아웃 하시겠습니까?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default) { (_) in
            self.signOut()
            let okAlert = UIAlertController(title: "확인", message: "로그아웃이 완료되었습니다.", preferredStyle: .alert)
            let okClick = UIAlertAction(title: "확인", style: .default) { _ in
            }
                okAlert.addAction(okClick)
                
                self.present(okAlert, animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func setNavigationBar() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "설정", style: .plain, target: nil, action: nil)
    }
}

//MARK: - Firebase 사용자 회원탈퇴 & Apple 탈퇴
extension SettingVC {
    // Firebase에서 사용자 데이터 삭제
    func deleteUserDataFromFirebase() {
        let firebaseAuth = Auth.auth()
        guard let currentUser = firebaseAuth.currentUser else {
            print("No user is currently signed in.")
            return
        }
        
        currentUser.delete { error in
            if let error = error {
                print("Error deleting user from Firebase: \(error.localizedDescription)")
            } else {
                print("User successfully deleted from Firebase.")
            }
        }
    }

    // 사용자에게 Apple ID를 삭제하도록 안내하는 메시지 표시
    func showDeleteAccountMessage() {
        let alert = UIAlertController(title: "회원 탈퇴", message: "정말로 회원탈퇴하시겠습니까?", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "회원 탈퇴", style: .destructive) { _ in
            self.deleteUserDataFromApple()
            let completeAlert = UIAlertController(title: "회원 탈퇴 완료", message: "회원 탈퇴가 완료되었습니다!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "확인", style: .default)
            
            alert.addAction(okAction)
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    //Apple 계정 탈퇴
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
      // Delete other information from the database...
        deleteUserDataFromFirebase()
      // Sign out on FirebaseAuth
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}


// MARK: subView & autolayout 구성
extension SettingVC {
    private func addSubviewsSettingVC() {
        view.backgroundColor = .mainBackground
        view.addSubview(tableView)
        view.addSubview(logoutButton)
        setNavigationBar()
    }
    
    private func autoLayoutSettingVC() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(logoutButton).offset(50)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        logoutButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.right.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

// MARK: - TableView 구성
extension SettingVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.dataSource[indexPath.row] {
            
        case let .profileItem(email, name, image):
            let cell = tableView.dequeueReusableCell(withIdentifier: ProfileCell.id, for: indexPath) as! ProfileCell
            cell.prapare(email: email, name: name, image: image)
            cell.backgroundColor = .mainBackground
            cell.delegate = self
            return cell
            
        case let .settingItem(title, iconImage, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingCell.id, for: indexPath) as! SettingCell
            cell.prepare(title: title, iconImage: iconImage)
            cell.backgroundColor = .mainBackground
            return cell
            
        case let .signOutItem(title, iconImage, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: SignOutCell.id, for: indexPath) as! SignOutCell
            cell.prepare(title: title, iconImage: iconImage)
            cell.backgroundColor = .mainBackground
            return cell
            
            
        }

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = dataSource[indexPath.row]
        
        switch selectedItem {
        case .profileItem(_, _, _):
                print("아무일도 일어나지 않음")
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
        case .signOutItem(_, _, let number):
            switch number {
            case 1:
                signOutAlert()
                print("로그아웃")
            case 2:
                print("회원 탈퇴")
                showDeleteAccountMessage()
            default:
                print("Error")
            }
        }
    }
}

