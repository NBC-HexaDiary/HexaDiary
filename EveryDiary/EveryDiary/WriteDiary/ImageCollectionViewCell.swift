//
//  ImageCollectionViewCell.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/14/24.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "ImageCell"
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    // 이미지 삭제 버튼
    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "trashRed"), for: .normal)
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // 삭제 버튼 탭 이벤트 처리를 위한 클로저
    var onDeleteButtonTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setViews()
        setupShadow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setViews() {
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        contentView.addSubViews([imageView, deleteButton])
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        deleteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.width.height.equalTo(25)
        }
    }
    
    private func setupShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.1
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 8.0
        self.layer.masksToBounds = false
    }
    @objc private func deleteButtonTapped() {
        // 클로저를 통해 삭제 버튼 탭 이벤트를 ViewController로 전달
        onDeleteButtonTapped?()
    }
    
    func configure(with image: UIImage) {
        imageView.image = image
    }
    func configureDeleteButton(hidden: Bool) {
        deleteButton.isHidden = hidden
    }
    func startJiggling() {
        // contentView에 "jiggling" 애니메이션이 사용 중인지 확인하고, 실행 중이라면 추가실행 방지
        guard contentView.layer.animation(forKey: "jiggling") == nil else { return }
        
        let angle = 0.005       // 회전 각도
        let translation = 0.5   // 위아래로 움직일 거리
        let duration = 0.3      // 반복 주기
        
        let animation = CAKeyframeAnimation(keyPath: "transform")   // transform 애니메이션 설정
        animation.values = [
            NSValue(caTransform3D: CATransform3DMakeRotation(CGFloat(-angle), 0.0, 0.0, 1.0)),
            NSValue(caTransform3D: CATransform3DMakeRotation(CGFloat(angle), 0.0, 0.0, 1.0))
        ]
        animation.autoreverses = true
        animation.duration = duration
        animation.repeatCount = Float.infinity
        
        let translationAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        translationAnimation.values = [-translation, translation]
        translationAnimation.autoreverses = true
        translationAnimation.duration = duration / 2
        translationAnimation.repeatCount = Float.infinity
        
        contentView.layer.add(animation, forKey: "jiggling")
        contentView.layer.add(translationAnimation, forKey: "transform")
    }
    func stopJiggling() {
        contentView.layer.removeAllAnimations()
    }
}
