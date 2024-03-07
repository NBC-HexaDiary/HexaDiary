//
//  DailyListCell.swift
//  EveryDiary
//
//  Created by eunsung ko on 3/7/24.
//

import UIKit

import SnapKit

class DailyListCell: UICollectionViewCell {
    static let id = "DailyListCell"
    
    private lazy var contentTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProDisplay-Bold", size: 20)
        return label
    }()
    private lazy var contentText: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProDisplay-Regular", size: 16)
        return label
    }()
    
    private lazy var weatherIcon = UIImageView()
    
    private lazy var emotionIcon = UIImageView()
    
    private lazy var dateOfWriting: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProDisplay-Regular", size: 12)
        return label
    }()
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviewDailyListCell()
        autoLayoutDailyListCell()
        contentView.backgroundColor = .mainCell
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowColor = UIColor(named: "mainTheme")?.cgColor
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        contentView.layer.cornerRadius = 20

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setDailyListCell(title: String, content: String, weather: String, emotion: String, date: String, imageName: String? = nil) {
        contentTitle.text = title
        contentText.text = content
        weatherIcon.image = UIImage(named: weather)
        emotionIcon.image = UIImage(named: emotion)
        dateOfWriting.text = date
        if let imageName = imageName {
            imageView.image = UIImage(named: imageName)
        }
    }
}

extension DailyListCell {
    private func addSubviewDailyListCell() {
        contentView.addSubview(contentTitle)
        contentView.addSubview(contentText)
        contentView.addSubview(weatherIcon)
        contentView.addSubview(emotionIcon)
        contentView.addSubview(dateOfWriting)
        contentView.addSubview(imageView)
    }
    private func autoLayoutDailyListCell() {
        contentTitle.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(15)
            make.height.equalTo(24)
            make.leading.equalTo(contentView.snp.leading).offset(15)
            make.trailing.equalTo(imageView.snp.leading).offset(-5)
        }
        contentText.snp.makeConstraints { make in
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
        imageView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(11)
            make.bottom.equalTo(contentView).offset(-11)
            make.trailing.equalTo(contentView).offset(-11)
            make.width.equalTo(imageView.snp.height)
        }
    }
}
