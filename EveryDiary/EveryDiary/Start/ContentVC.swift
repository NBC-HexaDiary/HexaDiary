//
//  ContentVC.swift
//  EveryDiary
//
//  Created by eunsung ko on 3/25/24.
//

import UIKit

import SnapKit

class ContentVC: UIViewController {
    
    var onboardingModel : OnboardingModel? {
        didSet {
            updateUI()
        }
    }
    
    private var imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 10
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var descriptionLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProRounded-Bold", size: 25)
        label.textColor = .loginBackground
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviewContentVC()
        autoLayoutContentVC()
    }
    
    private func addSubviewContentVC() {
        view.addSubview(imageView)
        view.addSubview(descriptionLabel)
    }
    
    private func autoLayoutContentVC() {
        descriptionLabel.snp.makeConstraints { make in
            make.top.trailing.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(50)
        }
        imageView.snp.makeConstraints { make in
            make.bottom.trailing.leading.equalTo(view.safeAreaLayoutGuide).inset(30)
            make.top.equalTo(descriptionLabel.snp.bottom).offset(16)
        }
    }
    
    private func updateUI() {
        if let model = onboardingModel {
            imageView.image = UIImage(named: model.descriptionImage)
            descriptionLabel.text = model.descriptionLabel
        }
    }
}
