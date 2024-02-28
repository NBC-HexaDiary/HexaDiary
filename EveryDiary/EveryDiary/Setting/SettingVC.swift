//
//  SettingVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit
import CryptoKit

import SnapKit
import FirebaseAuth
import Firebase
import GoogleSignIn

class SettingVC: UIViewController {
    
    private let settings: [SettingItem] = [
        SettingItem(title: "알림", iconName: "notification",number: 1),
        SettingItem(title: "잠금", iconName: "lock", number: 2)
    ]
    
    private lazy var loginButton: UIButton = {
        var config = UIButton.Configuration.plain()
        let loginBTN = UIButton(configuration: config)
        loginBTN.setImage(UIImage(named: "logIn"), for: .normal)
        loginBTN.tintColor = UIColor(named: "mainTheme")
        loginBTN.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return loginBTN
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SettingCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.rowHeight = 100
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .mainBackground
        tableView.separatorStyle = .none
        tableView.separatorColor = .mainTheme
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviewsSettingVC()
        autoLayoutSettingVC()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.selectRow(at: .none,
                            animated: true,
                            scrollPosition: .top)
    }
    
    private func addSubviewsSettingVC() {
        view.backgroundColor = .mainBackground
        view.addSubview(loginButton)
        view.addSubview(tableView)
        setNavigationBar()
    }
    
    private func autoLayoutSettingVC() {
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.equalTo(view.safeAreaLayoutGuide)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(loginButton).offset(50)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.bottom.equalTo(view).offset(-300)
        }
    }
    
    @objc func loginButtonTapped(){
        let loginVC = LoginVC()
        loginVC.modalPresentationStyle = .automatic
        self.present(loginVC, animated: true)
    }
    
    private func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error Signing out:  %@", signOutError)
        }
    }
    
    private func setNavigationBar() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "설정", style: .plain, target: nil, action: nil)
    }
}

extension SettingVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
        cell.backgroundColor = .mainBackground
        
        let setting = settings[indexPath.row]
        cell.titleLabel.text = setting.title
        cell.iconImageView.image = UIImage(named: setting.iconName)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = settings[indexPath.row]
        
        switch selectedItem.number {
        case 1:
            let notificationVC = NotificationVC()
            navigationController?.pushViewController(notificationVC, animated: true)
        case 2:
            let lockVC = LockVC()
            navigationController?.pushViewController(lockVC, animated: true)
        default:
            print("error")
        }
    }
}
