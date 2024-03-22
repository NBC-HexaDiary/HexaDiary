//
//  JournalCollectionViewCell.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 2/27/24.
//

import UIKit

import SnapKit

class JournalCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "JournalCollectionView"
    
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                self.contentView.backgroundColor = .subTheme
            } else {
                self.contentView.backgroundColor = .mainCell
            }
        }
    }
    
    private lazy var contentTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProDisplay-Bold", size: 18)
        return label
    }()
    
    private lazy var contentTextView: UITextView = {
        let view = UITextView()
        view.font = UIFont(name: "SFProDisplay-Regular", size: 14)
        view.textColor = .darkGray
        view.isEditable = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.isUserInteractionEnabled = false
        view.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.contentInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
        return view
    }()
    
    private lazy var weatherIcon = UIImageView()
    private lazy var emotionIcon = UIImageView()
    private lazy var dateOfWriting: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProDisplay-Regular", size: 12)
        label.textColor = .systemGray
        return label
    }()
    lazy var thumnailView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 10
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubView()
        setLayout()
        contentView.backgroundColor = .mainCell
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowColor = UIColor(named: "mainTheme")?.cgColor
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // UI 컴포넌트를 초기 상태로 리셋(cell 재사용시 다른 cell의 요소가 삽입되지 않도록)
        thumnailView.image = nil
        contentTitle.text = ""
        contentTextView.text = ""
        weatherIcon.image = nil
        emotionIcon.image = nil
        dateOfWriting.text = ""
    }
    
    func setJournalCollectionViewCell(title: String, content: String, weather: String, emotion: String, date: String, imageName: String? = nil) {
        contentTitle.text = title
        contentTextView.text = content
        dateOfWriting.text = date
        // 날씨 아이콘 업데이트
        if !weather.isEmpty, let weatherImage = UIImage(named: weather) {
            weatherIcon.image = weatherImage
        } else {
            weatherIcon.image = nil
        }
        if !emotion.isEmpty, let emotionImage = UIImage(named: emotion) {
            emotionIcon.image = emotionImage
        } else {
            emotionIcon.image = nil
        }
        if let imageName = imageName {
            thumnailView.image = UIImage(named: imageName)
        }
    }
    func setImage(_ image: UIImage?) {
        thumnailView.image = image
        thumnailView.isHidden = false
        updateLayoutForImageVisible(true)
    }
    func hideImage() {
        thumnailView.isHidden = true
        updateLayoutForImageVisible(false)
    }
    
    private func updateLayoutForImageVisible(_ isVisible: Bool) {
        if isVisible {
            // 이미지가 표시될 때
            contentTitle.snp.remakeConstraints { make in
                make.top.equalTo(contentView).offset(15)
                make.height.equalTo(24)
                make.leading.equalTo(contentView.snp.leading).offset(15)
                make.trailing.equalTo(thumnailView.snp.leading).offset(-5)
            }
            contentTextView.snp.remakeConstraints { make in
                make.top.equalTo(contentTitle.snp.bottom).offset(4)
                make.bottom.equalTo(weatherIcon.snp.top).offset(-4)
                make.leading.equalTo(contentTitle.snp.leading)
                make.trailing.equalTo(thumnailView.snp.leading).offset(-5)
            }
        } else {
            // 이미지가 숨겨졌을 때
            contentTitle.snp.remakeConstraints { make in
                make.top.equalTo(contentView).offset(15)
                make.height.equalTo(24)
                make.leading.equalTo(contentView.snp.leading).offset(15)
                make.trailing.equalTo(contentView.snp.trailing).offset(-15)
            }
            contentTextView.snp.remakeConstraints { make in
                make.top.equalTo(contentTitle.snp.bottom).offset(4)
                make.bottom.equalTo(weatherIcon.snp.top).offset(-4)
                make.leading.equalTo(contentTitle.snp.leading)
                make.trailing.equalTo(contentView.snp.trailing).offset(-15)
            }
        }
        // 변경된 제약 조건을 기반으로 레이아웃을 즉시 업데이트
        self.layoutIfNeeded()
    }
}

extension JournalCollectionViewCell {
    private func addSubView() {
        contentView.addSubview(contentTitle)
        contentView.addSubview(weatherIcon)
        contentView.addSubview(emotionIcon)
        contentView.addSubview(dateOfWriting)
        contentView.addSubview(thumnailView)
        contentView.addSubview(contentTextView)
    }
    private func setLayout() {
        contentTitle.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(15)
            make.height.equalTo(24)
            make.leading.equalTo(contentView.snp.leading).offset(15)
            make.trailing.equalTo(thumnailView.snp.leading).offset(-5)
        }
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(contentTitle.snp.bottom).offset(4)
            make.bottom.equalTo(weatherIcon.snp.top).offset(-4)
            make.leading.equalTo(contentTitle.snp.leading).offset(0)
            make.trailing.equalTo(contentTitle.snp.trailing).offset(0)
        }
        weatherIcon.snp.makeConstraints { make in
            make.bottom.equalTo(contentView.snp.bottom).offset(-17)
            make.leading.equalTo(emotionIcon.snp.trailing).offset(5)
            make.height.equalTo(15)
            make.width.equalTo(15)
        }
        emotionIcon.snp.makeConstraints { make in
            make.bottom.equalTo(weatherIcon.snp.bottom)
            make.leading.equalTo(dateOfWriting.snp.trailing).offset(5)
            make.height.equalTo(15)
            make.width.equalTo(15)
        }
        dateOfWriting.snp.makeConstraints { make in
            make.bottom.equalTo(weatherIcon.snp.bottom).offset(0)
            make.leading.equalTo(contentTitle.snp.leading).offset(0)
        }
        thumnailView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(11)
            make.bottom.equalTo(contentView).offset(-11)
            make.trailing.equalTo(contentView).offset(-11)
            make.width.equalTo(thumnailView.snp.height)
        }
    }
}
