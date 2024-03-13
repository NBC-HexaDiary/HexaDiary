//
//  HonorVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/23/24.
//

import UIKit
import SnapKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

#Preview{
    HonorVC()
}

class HonorVC: UIViewController {
    let db = Firestore.firestore()
    
    //딕셔너리. 키는 월(Int), 값은 일(Set)
    var monthlyDiaries = [Int: Set<String>]()
    
    private lazy var backgroundImage: UIImageView = {
        let backgroundImage = UIImageView()
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.image = UIImage(named: "honorBackground")
        return backgroundImage
    }()
    
    private lazy var honorSV: UIScrollView = {
        let honorSV = UIScrollView()
        honorSV.translatesAutoresizingMaskIntoConstraints = false
        honorSV.backgroundColor = .clear
        honorSV.showsVerticalScrollIndicator = false
        return honorSV
    }()
    
    private lazy var honorStackView: UIStackView = {
        let honorStackView = UIStackView()
        honorStackView.backgroundColor = .clear
        honorStackView.translatesAutoresizingMaskIntoConstraints = false
        honorStackView.axis = .vertical
        honorStackView.distribution = .fillEqually
        honorStackView.spacing = 10
        return honorStackView
    }()
    
    private func setupHonorStackViewButtons() {
        print("setupHonorStackViewButtons() called")
        for month in 1...12 {
            let button = UIButton()
            button.tag = month
            honorStackView.addArrangedSubview(button)
        }
    }
    
    private func setupButton() {
        print("setupButton() called")
        for (month, days) in monthlyDiaries {
            let cityButton = self.honorStackView.viewWithTag(month) as? UIButton
            
            if days.count == 0 {
                cityButton?.setImage(UIImage(named: "button0"), for: .normal)
            } else if days.count >= 1 && days.count <= 7 {
                cityButton?.setImage(UIImage(named: "button1"), for: .normal)
            } else if days.count >= 8 && days.count <= 14 {
                cityButton?.setImage(UIImage(named: "button2"), for: .normal)
            } else if days.count >= 15 && days.count <= 21 {
                cityButton?.setImage(UIImage(named: "button3"), for: .normal)
            } else if days.count >= 22 && days.count <= 27 {
                cityButton?.setImage(UIImage(named: "button4"), for: .normal)
            } else {
                cityButton?.setImage(UIImage(named: "button5"), for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(monthlyDiaries)
        addSubView()
        setupHonorStackViewButtons()
        setupButton()
        autoLayout()
    }
}

extension HonorVC {
    private func addSubView() {
        view.addSubview(backgroundImage)
        view.addSubview(honorSV)
        honorSV.addSubview(honorStackView)
    }
    
    private func autoLayout() {
        backgroundImage.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        honorSV.snp.makeConstraints{ make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
        honorStackView.snp.makeConstraints{ make in
            make.top.bottom.leading.trailing.equalTo(honorSV)
            make.width.equalTo(honorSV.snp.width)
            make.height.equalTo(honorSV.snp.height).multipliedBy(4)
        }
    }
    
    //MARK: - firebase
    private func fetchDiariesButtonData(completion: @escaping ([DiaryEntry]?, Error?) -> Void) {
        // 사용자가 로그인되어 있는지 확인
        guard let userID = DiaryManager.shared.getUserID() else {
            completion([], nil)
            return
        }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        DiaryManager.shared.listener = db.collection("users").document(userID).collection("diaries").whereField("year", isEqualTo: currentYear)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error listening for real-time updates: \(error)")
                    completion([], error)
                } else {
                    var diaries = [DiaryEntry]()
                    for document in querySnapshot!.documents {
                        if let diary = try? document.data(as: DiaryEntry.self) {
                            diaries.append(diary)
                        }
                    }
                    print("Fetched diaries: \(diaries)")
                    completion(diaries, nil)
                }
            }
    }
    
    private func sortDiariesByMonth(diaries: [DiaryEntry]) {
        for diary in diaries {
            let month = Calendar.current.component(.month, from: diary.date)
            let day = Calendar.current.component(.day, from: diary.date)
            print("Month \(month), Day \(day)")
            if self.monthlyDiaries[month] == nil {
                self.monthlyDiaries[month] = Set<String>()
            }
            self.monthlyDiaries[month]?.insert("\(day)")
        }
        self.setupButton()
    }
}



