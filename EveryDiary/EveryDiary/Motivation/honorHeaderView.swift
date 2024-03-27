//
//  honorHeaderView.swift
//  EveryDiary
//
//  Created by t2023-m0099 on 3/25/24.
//

import UIKit

class honorHeaderView: UICollectionReusableView {
    static let honorHeaderIdentifier = "honorHeaderViewIdentifier"
    
    let headerLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.textColor = .black
        headerLabel.font = UIFont.systemFont(ofSize: 16, weight: .light)
        return headerLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(headerLabel)
        
        headerLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
