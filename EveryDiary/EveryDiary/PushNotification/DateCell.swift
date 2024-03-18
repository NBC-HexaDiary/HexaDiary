//
//  DateCell.swift
//  EveryDiary
//
//  Created by eunsung ko on 3/14/24.
//

import UIKit

import SnapKit

class DateCell: UITableViewCell {
    static let id = "DateCell"
    
    private lazy var iconImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var titleLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProRounded-Regular", size: 20)
        label.textColor = .mainTheme
        return label
    }()
    
    private lazy var timeLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProRounded-Regular", size: 14)
        label.textColor = .mainTheme
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: DateCell.id)
        selectionStyle = .default
        addSubViewDateCell()
        autoLayoutDateCell()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubViewDateCell() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(timeLabel)
    }
    
    private func autoLayoutDateCell() {
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(25)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(timeLabel.snp.leading).inset(16)
            make.height.equalTo(30)
            make.width.equalTo(50)
        }
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    func prepare(title: String, iconImage: String, label: String) {
        self.titleLabel.text = title
        self.timeLabel.text = label
        self.iconImageView.image = UIImage(named: iconImage)
    }
}
