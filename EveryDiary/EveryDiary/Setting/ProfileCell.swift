//
//  ProfileCell.swift
//  EveryDiary
//
//  Created by eunsung ko on 2/29/24.
//

import UIKit

import SnapKit
import FirebaseAuth

class ProfileCell: UITableViewCell {
    static let id = "ProfileCell"

    private lazy var profileImageView : UIImageView = {
        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.layer.cornerRadius = 5
        return profileImageView
    }()
    
    private lazy var emailLabel : UILabel = {
        let emailLabel = UILabel()
        emailLabel.textColor = .subText
        emailLabel.font = UIFont(name: "SFProRounded-Regular", size: 14)
        return emailLabel
    }()
    
    private lazy var nameLabel : UILabel = {
        let nameLabel = UILabel()
        nameLabel.textColor = .mainTheme
        nameLabel.font = UIFont(name: "SFProRounded-Bold", size: 24)
        return nameLabel
    }()
    
    lazy var loginButton : UIButton = {
        let loginButton = UIButton()
        loginButton.layer.backgroundColor = UIColor(named: "mainTheme")?.cgColor
        loginButton.layer.shadowOpacity = 0.1
        loginButton.layer.shadowColor = UIColor(named: "mainTheme")?.cgColor
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        loginButton.layer.shadowRadius = 3
        loginButton.layer.cornerRadius = 10
        loginButton.setTitleColor(.mainCell, for: .normal)
        loginButton.setTitle("로그인", for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonTouchDown), for: .touchDown)
        loginButton.addTarget(self, action: #selector(loginButtonTouchOutside), for: .touchUpInside)
        return loginButton
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: ProfileCell.id)
        self.selectionStyle = .none
        contentView.layer.cornerRadius = 10
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowColor = UIColor(named: "mainTheme")?.cgColor
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        contentView.layer.backgroundColor = UIColor(named: "mainCell")?.cgColor
        addSubViewProfileCell()
        autoLayoutProfileCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func loginButtonTouchDown() {
        loginButton.layer.backgroundColor = UIColor(named: "subBackground")?.cgColor
    }
    
    @objc private func loginButtonTouchOutside() {
        loginButton.layer.backgroundColor = UIColor(named: "mainTheme")?.cgColor
    }
    
    private func addSubViewProfileCell() {
        addSubview(emailLabel)
        addSubview(nameLabel)
        addSubview(profileImageView)
        addSubview(loginButton)
    }
    
    private func autoLayoutProfileCell() {
        profileImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(50)
        }
        nameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-15)
            make.leading.equalTo(profileImageView.snp.trailing).offset(16)
            make.trailing.equalTo(loginButton.snp.leading).inset(16)
            make.bottom.equalTo(emailLabel.snp.top).offset(-10)
            make.height.equalTo(28)
        }
        emailLabel.snp.makeConstraints { make in
            make.leading.equalTo(profileImageView.snp.trailing).offset(16)
            make.trailing.equalTo(loginButton.snp.leading).inset(16)
            make.height.equalTo(20)
        }
        loginButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(70)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 4, bottom: 10, right: 4))
    }
    
    func prapare(email: String?, name: String?, image: String?, isLoggedIn: Bool) {
        self.emailLabel.text = email
        self.nameLabel.text = name
        self.profileImageView.image = UIImage(named: image ?? "profile")
        if isLoggedIn {
                self.loginButton.isHidden = true
                self.loginButton.isEnabled = false
        } else {
                self.loginButton.isHidden = false
                self.loginButton.isEnabled = true
        }
    }
}
