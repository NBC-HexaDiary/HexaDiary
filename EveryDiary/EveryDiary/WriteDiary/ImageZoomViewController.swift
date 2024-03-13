//
//  ImageZoomViewController.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/13/24.
//

import UIKit

class ImageZoomViewController: UIViewController, UIScrollViewDelegate {
    
    var image: UIImage!
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView(frame: view.bounds)
        view.minimumZoomScale = 1.0
        view.maximumZoomScale = 5.0
        view.delegate = self
        return view
    }()
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: self.image)
        view.contentMode = .scaleAspectFit
        view.frame = scrollView.bounds
        return view
    }()
    
    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        self.image = image
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // Do any additional setup after loading the view.
    }
    
    private func addSubViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
    }
    private func setLayout() {
        
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

}
