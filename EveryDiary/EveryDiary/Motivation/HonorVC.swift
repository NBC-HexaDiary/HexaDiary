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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        addSubView()
        autoLayout()
        fetchDiariesButtonData()
    }
    
    // MARK: - Button UI Update
    private func setupHonorStackViewButtonsAndLabels() {
        print("setupHonorStackViewButtons() called")
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
            
            let button = UIButton()
            button.tag = month
            button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
            
            let label = UILabel()
            label.text = "\(month)월"
            label.textAlignment = .center
            
            if month % 2 != 0 {
                // 홀수 월: 왼쪽 뷰에 버튼과 라벨 추가
                leftView.addSubview(button)
                leftView.addSubview(label)
            } else {
                // 짝수 월: 오른쪽 뷰에 버튼과 라벨 추가
                rightView.addSubview(button)
                rightView.addSubview(label)
            }
            
            button.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.centerX.equalToSuperview()
                //make.centerY.equalToSuperview()
            }
            label.snp.makeConstraints { make in
                make.top.equalTo(button.snp.bottom).offset(20)
                make.centerX.equalTo(button)
            }
        }
    }
    
    private func setupButton(monthlyDiaries: [Int: Set<String>]) {
        print("setupButton() called")
        for (month, days) in monthlyDiaries {
            let containerView = self.honorStackView.arrangedSubviews[month - 1]
            var button: UIButton?
            for subview in containerView.subviews {
                if let btn = subview.subviews.first(where: { $0 is UIButton }) as? UIButton {
                    button = btn
                    break
                }
            }
            
            guard let button = button else {
                continue
            }
            if days.isEmpty {
                button.setImage(UIImage(named: "button0"), for: .normal)
            } else {
                switch days.count {
                case 1...7:
                    button.setImage(UIImage(named: "button1"), for: .normal)
                case 8...14:
                    button.setImage(UIImage(named: "button2"), for: .normal)
                case 15...21:
                    button.setImage(UIImage(named: "button3"), for: .normal)
                case 22...27:
                    button.setImage(UIImage(named: "button4"), for: .normal)
                default:
                    button.setImage(UIImage(named: "button5"), for: .normal)
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
    }
}
    
//MARK: - firebase
extension HonorVC {
    private func fetchDiariesButtonData() {
        // 사용자가 로그인되어 있는지 확인
        guard let userID = DiaryManager.shared.getUserID() else {
            return
        }
        // 현재 년도 가져오기
        let currentYear = Calendar.current.component(.year, from: Date())
        // 데이터가 있는 월을 저장할 집합
        var existingMonths = Set<Int>()
        
        DiaryManager.shared.fetchDiaries { [weak self] (diaries, error) in
            guard let self = self, let diaries = diaries, error == nil else {
                // 에러 처리...
                return
            }
            
            // 월별 다이어리 구분
            var monthlyDiaries = [Int: Set<Int>]()
            for diary in diaries {
                let month = Calendar.current.component(.month, from: diary.date)
                let day = Calendar.current.component(.day, from: diary.date)
                if monthlyDiaries[month] == nil {
                    monthlyDiaries[month] = Set<Int>()
                }
                monthlyDiaries[month]?.insert(day)
                // 데이터가 있는 월을 추가
                existingMonths.insert(month)
            }
            print("Fetched diaries: \(diaries)")
            for month in 1...12 {
                if !existingMonths.contains(month) {
                    // 데이터가 없는 월에 대한 처리
                    print("No data found for month \(month)")
                    // 빈 배열로 처리
                    monthlyDiaries[month] = []
                }
            }
            self.sortDiariesByMonth(diaries: diaries ?? [], monthlyDiaries: monthlyDiaries)
        }
    }
    
    private func sortDiariesByMonth(diaries: [DiaryEntry], monthlyDiaries: [Int: Set<Int>]) {
        // 다이어리 데이터가 비어있을 경우 처리
        guard !diaries.isEmpty else {
            print("Diaries data is empty.")
            return
        }
        
        var monthlyDiariesWithStrings = [Int: Set<String>]()
        
        for (month, days) in monthlyDiaries {
            var stringDays = Set<String>()
            for day in days {
                stringDays.insert("\(day)")
            }
            monthlyDiariesWithStrings[month] = stringDays
        }
        DispatchQueue.main.async {
            self.setupHonorStackViewButtonsAndLabels()
            self.setupButton(monthlyDiaries: monthlyDiariesWithStrings)
        }
    }
    @objc private func buttonTapped() {
        let detailVC = DetailVC()
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
//    func navigateToMotivationVC(month: Int, days: Set<String>) {
//        let detailVC = DetailVC()
//        detailVC.configure(month: month, days: days)
//        navigationController?.pushViewController(detailVC, animated: true)
//    }
    
    private func setNavigationBar() {
        navigationController?.navigationBar.tintColor = .black
    }
}
