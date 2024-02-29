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
        deleteTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        return deleteTitleLabel
    }()
    
    private lazy var signOutImageView : UIImageView = {
        let signOutImageView = UIImageView()
        signOutImageView.contentMode = .scaleAspectFit
        signOutImageView.translatesAutoresizingMaskIntoConstraints = false
        return signOutImageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: SignOutCell.id)
        
        selectionStyle = .none
        contentView.layer.cornerRadius = 10
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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            contentView.layer.borderWidth = 2
            contentView.layer.borderColor = UIColor(named: "mainError")?.cgColor
        } else {
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = UIColor(named: "subBackground")?.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 16, left: 4, bottom: 16, right: 4))
    }
    
    func prepare(title: String, iconImage: String) {
        self.signOutLabel.text = title
        self.signOutImageView.image = UIImage(named: iconImage)
    }

}
