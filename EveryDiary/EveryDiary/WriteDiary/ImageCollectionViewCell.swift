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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContentView()
        setupShadow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupContentView() {
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.1
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 8.0
        self.layer.masksToBounds = false
    }
    
    func configure(with image: UIImage) {
        imageView.image = image
    }
}
