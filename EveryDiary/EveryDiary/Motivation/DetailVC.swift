//
//  DetailVC.swift
//  EveryDiary
//
//  Created by t2023-m0099 on 3/15/24.
//

import UIKit

class DetailVC: UIViewController {
    var month: Int?
    var days: Set<String>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .purple
    }
    
    func configure(month: Int, days: Set<String>) {
        self.month = month
        self.days = days
    }
}
