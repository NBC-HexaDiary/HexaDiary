//
//  DateConditionSelectVC.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 2/28/24.
//

import UIKit

import SnapKit

protocol DateConditionSelectDelegate: AnyObject {
    func didSelectCondition(_ emotion: String, type: ConditionType)
}

// tap한 버튼에 따라서 collectionView에 감정 또는 날씨를 선택
enum ConditionType {
    case emotion
    case weather
}

class DateConditionSelectVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: DateConditionSelectDelegate?
    var conditionType: ConditionType = .emotion
    
    private let emotions = ["Smiling face with smiling eyes", "Grinning face", "Neutral face", "Disappointed but relieved face", "Persevering face", "Loudly crying face", "Pouting face", "Sleeping face", "Face screaming in fear", "Face vomiting", "Face with medical mask"]
    
    private let weathers = ["u_sun", "u_cloud-sun", "u_clouds", "fi_wind", "u_cloud-showers-heavy", "u_moon", "u_cloud-moon", "u_rainbow", "u_snowflake", "u_thunderstorm"]
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(#function)
        view.addSubview(collectionView)
        let arrowSize: CGFloat = 13
        collectionView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
                collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
                collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch conditionType {
        case .emotion:
            return emotions.count
        case .weather:
            return weathers.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        // 이전에 추가된 모든 서브뷰를 제거
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // 감정(String)에 해당하는 이미지 설정
        let condition = conditionType == .emotion ? emotions[indexPath.row] : weathers[indexPath.row]
        
        let imageView = UIImageView(image: UIImage(named: condition))
        imageView.contentMode = .scaleAspectFit
        imageView.frame = cell.contentView.bounds
        cell.contentView.addSubview(imageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCondition = conditionType == .emotion ? emotions[indexPath.row] : weathers[indexPath.row]
        delegate?.didSelectCondition(selectedCondition, type: conditionType)
        dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.height * 0.7
        let width = height
        return CGSize(width: width, height: height)
    }
}

