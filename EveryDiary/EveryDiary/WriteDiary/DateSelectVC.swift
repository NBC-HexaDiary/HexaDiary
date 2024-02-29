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
        picker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        return picker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
//        datePicker.backgroundColor = .white

        addSubViews()
        makeConstraints()
        
//        tapGustureCheck()
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        delegate?.didSelectDate(sender.date)
    }
    
//    private func tapGustureCheck() {
//        // contentView로 구현했을때, contentView 밖을 선택하는 gesture를 추적
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutsideContentView))
//        view.addGestureRecognizer(tapGesture)
//        contentView.isUserInteractionEnabled = true
//    }
//    
//    // gesture가 감지되면, dismiss시키는 메서드
//    @objc private func handleTapOutsideContentView(_ sender: UITapGestureRecognizer) {
//        let location = sender.location(in: view)
//        if !contentView.frame.contains(location) {
//            dismiss(animated: false, completion: nil)
//        }
//    }
    
    private func addSubViews() {
//        self.view.addSubview(contentView)
//        contentView.addSubview(dateView)
        self.view.addSubview(datePicker)
    }
    
    private func makeConstraints() {
//        contentView.snp.makeConstraints { make in
//            make.center.equalToSuperview()
//            make.width.equalTo(250)
//            make.height.equalTo(250)
//        }
        
        datePicker.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
