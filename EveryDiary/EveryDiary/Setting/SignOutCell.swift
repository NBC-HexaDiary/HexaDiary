//
//  DeleteProfileCell.swift
//  EveryDiary
//
//  Created by eunsung ko on 2/29/24.
//

import UIKit

import SnapKit

class SignOutCell: UITableViewCell {
    static let id = "SignOutCell"

    
    private lazy var signOutLabel : UILabel = {
        let deleteTitleLabel = UILabel()
        deleteTitleLabel.font = UIFont(name: "SFProRounded-Regular", size: 20)
        deleteTitleLabel.textColor = .mainError
        return deleteTitleLabel
    }()
    
    private lazy var signOutImageView : UIImageView = {
        let signOutImageView = UIImageView()
        signOutImageView.contentMode = .scaleAspectFit
        return signOutImageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: SignOutCell.id)
        
        selectionStyle = .none
        contentView.layer.cornerRadius = 10
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowColor = UIColor(named: "mainTheme")?.cgColor
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        contentView.layer.backgroundColor = UIColor(named: "mainCell")?.cgColor
        addSubViewSignOutCell()
        autoLayoutSignOutCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubViewSignOutCell() {
        addSubview(signOutLabel)
        addSubview(signOutImageView)
    }
    
    private func autoLayoutSignOutCell() {
        signOutImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        signOutLabel.snp.makeConstraints { make in
            make.leading.equalTo(signOutImageView.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
            make.trailing.equalToSuperview()
        }
    }
    
    override func setSelected(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            contentView.layer.backgroundColor = UIColor(named: "subTheme")?.cgColor
        } else {
            contentView.layer.backgroundColor = UIColor(named: "mainCell")?.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 4, bottom: 10, right: 4))
    }
    
    func prepare(title: String, iconImage: String, isLoggedIn: Bool) {
        if isLoggedIn {
            self.signOutLabel.isHidden = false
            self.signOutImageView.isHidden = false
            self.signOutLabel.text = title
            self.signOutImageView.image = UIImage(named: iconImage)
            self.contentView.layer.isHidden = false
        } else {
            self.signOutLabel.isHidden = true
            self.signOutImageView.isHidden = true
            self.contentView.layer.isHidden = true // 레이어를 숨김
        }
    }

}
