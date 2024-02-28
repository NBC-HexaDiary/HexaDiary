//
//  SettingVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit

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
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 20
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .subTheme
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SettingCell.self, forCellWithReuseIdentifier: "SettingCell")
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviewsSettingVC()
        autoLayoutSettingVC()
    }
    
    private func addSubviewsSettingVC() {
        view.backgroundColor = .mainBackground
        view.addSubview(loginButton)
        view.addSubview(collectionView)
    }
    
    private func autoLayoutSettingVC() {
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.equalTo(view.safeAreaLayoutGuide)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(loginButton).offset(50)
            make.leading.equalTo(view.safeAreaLayoutGuide)
            make.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-50)
        }
    }
    
    @objc func loginButtonTapped(){
        let loginVC = LoginVC()
        loginVC.modalPresentationStyle = .automatic
        self.present(loginVC, animated: true)
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error Signing out:  %@", signOutError)
        }
    }
}

extension SettingVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return settings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SettingCell", for: indexPath) as! SettingCell
        let setting = settings[indexPath.item]
        cell.textLabel.text = setting.title
        cell.iconImageView.image = UIImage(named: setting.iconName)
        
        let separatorView = UIView()
        separatorView.backgroundColor = .mainTheme
        cell.addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedItem = settings[indexPath.item]
        
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let height: CGFloat = 50
        return CGSize(width: width, height: height)
    }
}
