//
//  ImageZoomCollectionViewController.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/15/24.
//

import UIKit

class ImageZoomCollectionViewController: UIViewController {
    
    var images: [UIImage] = []  // 이미지 배열
    var initialIndex: Int = 0 // 초기에 표시할 인덱스
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: self.view.bounds.width, height: self.view.bounds.height)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImageZoomCollectionViewCell.self, forCellWithReuseIdentifier: ImageZoomCollectionViewCell.reuseIdentifier)
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setCollectionView()
        
    }
    
    private func setCollectionView() {
        view.addSubview(collectionView)
        collectionView.frame = view.bounds
        collectionView.scrollToItem(at: IndexPath(item: initialIndex, section: 0), at: .centeredHorizontally, animated: false)
    }
}

extension ImageZoomCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource, ImageZoomCollectionViewCellDelegate {
    func cellDidRequestDismiss(_ cell: ImageZoomCollectionViewCell) {
        dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageZoomCollectionViewCell.reuseIdentifier, for: indexPath) as? ImageZoomCollectionViewCell else {
            fatalError("Unable to dequeue ImageZoomCollectionViewCell")
        }
        let image = images[indexPath.item]
        cell.delegate = self    // cellDidRequestDismiss delegate패턴
        cell.configure(with: image)
        return cell
    }
    
    
}
