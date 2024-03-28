//
//  honorHeaderView.swift
//  EveryDiary
//
//  Created by t2023-m0099 on 3/25/24.
//

import UIKit

import SnapKit

class honorHeaderView: UICollectionReusableView {
    static let honorHeaderIdentifier = "honorHeaderViewIdentifier"
    
    let headerLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.textColor = .mainTheme
        headerLabel.textAlignment = .right
        headerLabel.font = UIFont(name: "SFProDisplay-Bold", size: 18)
        return headerLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.top.equalToSuperview().inset(4)
            make.width.equalToSuperview().inset(32)
            make.height.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
