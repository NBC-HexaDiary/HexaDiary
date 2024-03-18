//
//  DayPicker.swift
//  EveryDiary
//
//  Created by eunsung ko on 3/14/24.
//

import UIKit

import SnapKit

class DayPickerCell: UITableViewCell {
    static let id = "DayPickerCell"

    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProRounded-Regular", size: 20)
        label.textColor = .mainTheme
        label.textAlignment = .left
        return label
    }()
    
    private lazy var checkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = .check
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: DayPickerCell.id)
        addSubviewDayPickerCell()
        autoLayoutDayPickerCell()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviewDayPickerCell() {
        addSubview(dayLabel)
        addSubview(checkImageView)
    }
    
    private func autoLayoutDayPickerCell() {
        dayLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(32)
            make.trailing.equalTo(checkImageView.snp.trailing).inset(16)
        }
        checkImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
    }
    
    func prepare(title: String, isSelected: Bool) {
        dayLabel.text = title
        checkImageView.isHidden = !isSelected
    }
}
