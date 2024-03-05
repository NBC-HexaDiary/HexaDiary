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
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
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
        nameLabel.font = UIFont(name: "SFProRounded-Regular", size: 20)
        return nameLabel
    }()
    
    lazy var loginButton : UIButton = {
        var config = UIButton.Configuration.plain()
        let loginButton = UIButton()
        loginButton.layer.borderWidth = 1
        loginButton.layer.borderColor = UIColor(named: "mainTheme")?.cgColor
        loginButton.layer.cornerRadius = 10
        loginButton.setTitleColor(.mainTheme, for: .normal)
        loginButton.setTitle("로그인", for: .normal)
        return loginButton
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: ProfileCell.id)
        self.selectionStyle = .none
        contentView.layer.cornerRadius = 10
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor(named: "subBackground")?.cgColor
        addSubViewProfileCell()
        autoLayoutProfileCell()
        controlButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubViewProfileCell() {
        addSubview(emailLabel)
        addSubview(nameLabel)
        addSubview(profileImageView)
        addSubview(loginButton)
    }
    
    
    private func controlButton() {
        let user = Auth.auth().currentUser
        
        if user != nil {
            loginButton.isEnabled = false
            loginButton.isHidden = true
        } else {
            loginButton.isEnabled = true
            loginButton.isHidden = false
        }
        self.loginButton.setNeedsDisplay()
    }
    
    private func autoLayoutProfileCell() {
        profileImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(50)
        }
        nameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-12)
            make.leading.equalTo(profileImageView.snp.trailing).offset(16)
            make.trailing.equalTo(loginButton.snp.leading).inset(16)
            make.bottom.equalTo(emailLabel.snp.top).offset(-6)
            make.height.equalTo(24)
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
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0))
    }
    
    func prapare(email: String?, name: String?, image: String?) {
        self.emailLabel.text = email
        self.nameLabel.text = name
        self.profileImageView.image = UIImage(named: image ?? "profile")
    }
}
