//
//  DateSelectVC.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 2/27/24.
//

import UIKit

import SnapKit

protocol DateSelectDelegate: AnyObject {
    func didSelectDate(_ date: Date)
}

class DateSelectVC: UIViewController {
    weak var delegate: DateSelectDelegate?
    
    var selectedDate: Date?
    
    private lazy var contentView : UIView = {
        let contentView = UIView()
        contentView.layer.cornerRadius = 15
        contentView.clipsToBounds = true
        return contentView
    }()
    
    private lazy var datePicker: UIDatePicker = {
        var picker = UIDatePicker()
        picker.preferredDatePickerStyle = .inline
        picker.datePickerMode = .date
        picker.locale = Locale(identifier: "ko-KR")
        picker.tintColor = .mainTheme
        picker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        // 최대 선택가능한 날짜 지정
        var calendar = Calendar(identifier: .gregorian)
        let currentDate = Date()
        var components = DateComponents()
        components.calendar = calendar
        let maxDate = calendar.date(byAdding: components, to: currentDate)
        picker.maximumDate = maxDate
        return picker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addSubViews()
        makeConstraints()
        deliverDate()
    }
    private func deliverDate() {
        if let selectedDate = selectedDate {
            datePicker.date = selectedDate
        }
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        delegate?.didSelectDate(sender.date)
    }
    
    private func addSubViews() {
        self.view.addSubview(datePicker)
    }
    
    private func makeConstraints() {
        datePicker.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
