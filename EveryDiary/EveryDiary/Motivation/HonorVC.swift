//
//  HonorVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/23/24.
//

import UIKit

import SnapKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class HonorVC: UIViewController {
    let db = Firestore.firestore()
    
    private var dataByYearMonth = [String: Set<Int>]()
    var listener: ListenerRegistration?
    
    private lazy var backgroundImage: UIImageView = {
        let backgroundImage = UIImageView()
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.image = UIImage(named: "honorBackground")
        return backgroundImage
    }()
    
    private lazy var honorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 5)
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        
        let honorCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        honorCollectionView.backgroundColor = .clear
        honorCollectionView.register(honorCollectionViewCell.self, forCellWithReuseIdentifier: honorCollectionViewCell.honorIdentifier)
        honorCollectionView.register(honorHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "honorHeaderViewIdentifier")
        
        return honorCollectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        honorCollectionView.delegate = self
        honorCollectionView.dataSource = self
        setNavigationBar()
        addSubView()
        autoLayout()
        fetchDiariesButtonData()
    }
}

//MARK: - UI 설정
extension HonorVC {
    private func addSubView() {
        view.addSubview(backgroundImage)
        view.addSubview(honorCollectionView)
    }
    
    private func autoLayout() {
        backgroundImage.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        honorCollectionView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

//MARK: - firebase
extension HonorVC {
    private func fetchDiariesButtonData() {
        DiaryManager.shared.fetchDiaries { [weak self] (diaries, error) in
            guard let self = self, let diaries = diaries, error == nil else {
                return
            }
            let filteredDiaries = diaries.filter { !$0.isDeleted }.sorted(by: { $0.date > $1.date })
            for diary in filteredDiaries {
                let yearMonth = DateFormatter.yyyyMM.string(from: diary.date)
                let day = Calendar.current.component(.day, from: diary.date)
                dataByYearMonth[yearMonth, default: []].insert(day)
            }
            print("Data by year and month: \(self.dataByYearMonth)")
            DispatchQueue.main.async {
                 self.honorCollectionView.reloadData()
             }
        }
    }
    
    private func setNavigationBar() {
        navigationController?.navigationBar.tintColor = .black
    }
}

// MARK: - UICollectionViewDataSource
extension HonorVC: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        print("numberOfSections : \(dataByYearMonth.keys)")
        if dataByYearMonth.isEmpty {
            let message = UILabel(frame: CGRect(x: 0, y: 0, width: honorCollectionView.bounds.width, height: honorCollectionView.bounds.height))
            message.text = "당신의 여정을 시작하세요."
            message.font = UIFont(name: "SFProDisplay-Regular", size: 16)
            message.textColor = .black
            message.textAlignment = .center
            honorCollectionView.backgroundView = message
            return 0
        } else {
            return dataByYearMonth.keys.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = honorCollectionView.dequeueReusableCell(withReuseIdentifier: honorCollectionViewCell.honorIdentifier, for: indexPath) as? honorCollectionViewCell else {
            return UICollectionViewCell()
        }
        let yearMonth = Array(dataByYearMonth.keys)[indexPath.section]
        let numberOfDays = dataByYearMonth[yearMonth]?.count ?? 0
        
        switch numberOfDays {
        case 1...7:
            cell.images.image = UIImage(named: "button1")
        case 8...14:
            cell.images.image = UIImage(named: "button2")
        case 15...21:
            cell.images.image = UIImage(named: "button3")
        case 22...27:
            cell.images.image = UIImage(named: "button4")
        default:
            cell.images.image = UIImage(named: "button5")
        }
        cell.images.contentMode = .scaleAspectFit
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerView = honorCollectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: honorHeaderView.honorHeaderIdentifier, for: indexPath) as? honorHeaderView else {
            fatalError("Failed to dequeue honor header view")
        }
        let keys = Array(dataByYearMonth.keys)
        let keyForSection = keys[indexPath.section]
        headerView.headerLabel.text = keyForSection
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 16) // 헤더의 너비와 높이 설정
    }
}

