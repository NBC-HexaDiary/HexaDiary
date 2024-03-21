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
    var monthlyDiaries = [Int: Set<Int>]()
    var monthlyDiariesWithStrings = [Int: Set<String>]()
    var listener: ListenerRegistration?
    
    private lazy var backgroundImage: UIImageView = {
        let backgroundImage = UIImageView()
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.image = UIImage(named: "honorBackground")
        return backgroundImage
    }()
    
    private lazy var honorSV: UIScrollView = {
        let honorSV = UIScrollView()
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
    
    private lazy var centerLabel: UILabel = {
        let centerLabel = UILabel()
        
        centerLabel.text = "당신의 여정을 시작하세요."
        centerLabel.font = UIFont(name: "SFProDisplay-Regular", size: 16)
        centerLabel.textColor = .black

        return centerLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        addSubView()
        autoLayout()
        fetchDiariesButtonData()
    }
    
    // MARK: - Button UI Update
    private func setupHonorStackViewImagessAndLabels() {
        for month in 1...12 {
            let containerView = UIView()
            honorStackView.addArrangedSubview(containerView)
            
            let leftView = UIView()
            let rightView = UIView()
            
            containerView.addSubview(leftView)
            containerView.addSubview(rightView)
            
            leftView.snp.makeConstraints { make in
                make.left.equalTo(containerView.snp.left).offset(30)
                make.top.bottom.equalTo(containerView)
                make.width.equalTo(containerView.snp.width).multipliedBy(0.5)
            }
            
            rightView.snp.makeConstraints { make in
                make.right.equalTo(containerView.snp.right).offset(-30)
                make.top.bottom.equalTo(containerView)
                make.width.equalTo(leftView.snp.width)
            }
            
            let imageView = UIImageView()
            imageView.tag = month
            
            let label = UILabel()
            label.text = "\(month)월"
            label.textAlignment = .center
            
            if month % 2 != 0 {
                leftView.addSubview(imageView)
                leftView.addSubview(label)
            } else {
                rightView.addSubview(imageView)
                rightView.addSubview(label)
            }
            
            imageView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.centerX.equalToSuperview()
                //make.centerY.equalToSuperview()
            }
            label.snp.makeConstraints { make in
                make.top.equalTo(imageView.snp.bottom).offset(20)
                make.centerX.equalTo(imageView)
            }
        }
    }
    
    private func setupImages(monthlyDiaries: [Int: Set<String>]) {
        for (month, days) in monthlyDiaries {
            let containerView = self.honorStackView.arrangedSubviews[month - 1]
            var imageView: UIImageView?
            for subview in containerView.subviews {
                if let imgView = subview.subviews.first(where: { $0 is UIImageView }) as? UIImageView {
                    imageView = imgView
                    break
                }
            }
            
            guard let imageView = imageView else {
                continue
            }
            
            if days.isEmpty || monthlyDiaries.isEmpty {
                imageView.image = UIImage(named: "button0")
            } else {
                switch days.count {
                case 1...7:
                    imageView.image = UIImage(named: "button1")
                case 8...14:
                    imageView.image = UIImage(named: "button2")
                case 15...21:
                    imageView.image = UIImage(named: "button3")
                case 22...27:
                    imageView.image = UIImage(named: "button4")
                default:
                    imageView.image = UIImage(named: "button5")
                }
            }
        }
    }
}
//MARK: - UI 설정
extension HonorVC {
    private func addSubView() {
        view.addSubview(backgroundImage)
        view.addSubview(honorSV)
        honorSV.addSubview(honorStackView)
        
        if DiaryManager.shared.getUserID() == nil {
            honorSV.addSubview(centerLabel)
        } else {
            centerLabel.removeFromSuperview()
        }
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
            make.height.equalTo(honorSV.snp.height).multipliedBy(2)
        }
        if DiaryManager.shared.getUserID() == nil {
            centerLabel.snp.makeConstraints { make in
                make.centerX.centerY.equalTo(view.safeAreaLayoutGuide)
            }
        }
    }
}

//MARK: - firebase
extension HonorVC {
    private func fetchDiariesButtonData() {
        guard DiaryManager.shared.getUserID() != nil else {
            return
        }
        _ = Calendar.current.component(.year, from: Date())
        // 데이터가 있는 월을 저장할 집합
        var existingMonths = Set<Int>()
        
        DiaryManager.shared.fetchDiaries { [weak self] (diaries, error) in
            guard let self = self, let diaries = diaries, error == nil else {
                return
            }
            let filteredDiaries = diaries.filter { !$0.isDeleted }
            for diary in filteredDiaries {
                let month = Calendar.current.component(.month, from: diary.date)
                let day = Calendar.current.component(.day, from: diary.date)
                if monthlyDiaries[month] == nil {
                    monthlyDiaries[month] = Set<Int>()
                }
            
                monthlyDiaries[month]?.insert(day)
                existingMonths.insert(month)
            }
//            print("Monthly diaries: \(monthlyDiaries)")
//            print("Fetched diaries: \(diaries)")
            for month in 1...12 {
                if !existingMonths.contains(month) {
//                    print("No data found for month \(month)")
                    monthlyDiaries[month] = []
                }
            }
            self.sortDiariesByMonth(diaries: diaries , monthlyDiaries: monthlyDiaries)
        }
    }
    
    private func sortDiariesByMonth(diaries: [DiaryEntry], monthlyDiaries: [Int: Set<Int>]) {
        guard !diaries.isEmpty else {
            print("Diaries data is empty.")
            return
        }
        for (month, days) in monthlyDiaries {
            var stringDays = Set<String>()
            for day in days {
                stringDays.insert("\(day)")
            }
            monthlyDiariesWithStrings[month] = stringDays
        }
        DispatchQueue.main.async {
            self.setupHonorStackViewImagessAndLabels()
            self.setupImages(monthlyDiaries: self.monthlyDiariesWithStrings)
        }
    }
    
    private func setNavigationBar() {
        navigationController?.navigationBar.tintColor = .black
    }
}


