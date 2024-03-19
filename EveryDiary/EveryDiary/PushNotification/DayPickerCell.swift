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
    
    weak var delegate: DayPickerCellDelegate?

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
    
    @objc private func dayTapped() {
        guard let day = dayLabel.text else { return }
        // checkImageView.isHidden 값을 먼저 반전시킵니다.
        // 이는 실제 선택 상태의 반대입니다. 따라서, 이 값을 토글하기 전에 값을 반전시킵니다.
        checkImageView.isHidden = !checkImageView.isHidden
        // 이제 isSelected는 사용자의 최종 선택 상태를 올바르게 반영합니다.
        let isSelected = !checkImageView.isHidden
        // delegate에 최종 상태를 알립니다.
        delegate?.selectDay(self, didPickDay: day, isSelected: isSelected)

    }
    
    func prepare(title: String, isSelected: Bool) {
        dayLabel.text = title
        checkImageView.isHidden = !isSelected
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dayTapped))
        self.addGestureRecognizer(tapGesture)
    }
}

//MARK: - 요일 선택 시, delegate 패턴 사용하여 데이터 전달
protocol DayPickerCellDelegate: AnyObject {
    func selectDay(_ cell: DayPickerCell, didPickDay day: String, isSelected: Bool)
}
