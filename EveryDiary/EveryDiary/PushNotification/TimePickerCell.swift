//
//  TimePicker.swift
//  EveryDiary
//
//  Created by eunsung ko on 3/14/24.
//

import UIKit

import SnapKit

class TimePickerCell: UITableViewCell {
    static let id = "TimePickerCell"

    private lazy var timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.isUserInteractionEnabled = true
        return picker
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: TimePickerCell.id)
        selectionStyle = .none
        addSubViewTimePickerCell()
        autoLayoutTimePickerCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubViewTimePickerCell() {
        contentView.addSubview(timePicker)
    }
    
    private func autoLayoutTimePickerCell() {
        timePicker.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
    }
    
    func configure(with date: Date?) {
        timePicker.date = date ?? Date()
    }
}
