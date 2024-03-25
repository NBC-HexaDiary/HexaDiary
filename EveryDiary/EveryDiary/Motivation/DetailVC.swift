//
//  DetailVC.swift
//  EveryDiary
//
//  Created by t2023-m0099 on 3/21/24.
//

import UIKit

#Preview{
    DetailVC()
}

class DetailVC: UIViewController {
    var images: UIImageView = {
        let images = UIImageView()
        images.image = UIImage(named: "button1")
        return images
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(images)
        
//        images.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
    }
}
