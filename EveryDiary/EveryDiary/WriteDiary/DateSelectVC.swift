//
//  DateSelectVC.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 2/27/24.
//

import UIKit

protocol DateSelectDelegate: AnyObject {
    func didSelectDate(_ Date: Date)
}

class DateSelectVC: UIViewController {
    private lazy var contentView : UIView = {
        let contentView = UIView()
        contentView.layer.cornerRadius = 15
        contentView.clipsToBounds = true
        return contentView
    }()
    
    private lazy var dateView: UICalendarView = {
        var view = UICalendarView()
        view.wantsDateDecorations = true
        return view
    }()
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black.withAlphaComponent(0.2)
        dateView.backgroundColor = .white
        
        addSubViews()
        makeConstraints()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutsideContentView))
        view.addGestureRecognizer(tapGesture)
        contentView.isUserInteractionEnabled = true
    }
    
    @objc private func handleTapOutsideContentView(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        if !contentView.frame.contains(location) {
            dismiss(animated: false, completion: nil)
        }
    }
    
    private func addSubViews() {
        self.view.addSubview(contentView)
        contentView.addSubview(dateView)
    }
    
    private func makeConstraints() {
        contentView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(70)
            make.leading.equalTo(self.view.safeAreaLayoutGuide.snp.leading).offset(16)
            make.width.equalTo(250)
            make.height.equalTo(250)
        }
        
        dateView.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top)
            make.bottom.equalTo(contentView.snp.bottom)
            make.leading.equalTo(contentView.snp.leading)
            make.trailing.equalTo(contentView.snp.trailing)
        }
    }
}
