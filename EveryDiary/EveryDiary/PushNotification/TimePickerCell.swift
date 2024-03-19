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
    
    weak var delegate: TimePickerCellDelegate?
    
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
        timePicker.addTarget(self, action: #selector(timePickerChanged(_:)), for: .valueChanged)
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
    
    @objc private func timePickerChanged(_ picker: UIDatePicker) {
        delegate?.selectTime(self, didPickTime: picker.date)
    }
    
    func configure(with date: Date?) {
        timePicker.date = date ?? Date()
    }
}

//MARK: - 시간 선택 시, delegate 패턴 사용하여 데이터 전달
protocol TimePickerCellDelegate: AnyObject {
    func selectTime(_ cell: TimePickerCell, didPickTime date: Date)
}
