//
//  CalendarListVC.swift
//  EveryDiary
//
//  Created by eunsung ko on 2/29/24.
//

import UIKit

class CalendarListVC: UIViewController {
    var selectedDiaries: [DiaryEntry] = [] // 선택된 일기들을 저장하는 프로퍼티

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .mainBackground
    }
}
