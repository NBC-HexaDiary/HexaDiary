//
//  ImageZoomCollectionViewCell.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/15/24.
//

import UIKit

protocol ImageZoomCollectionViewCellDelegate: AnyObject {
    func cellDidRequestDismiss(_ cell: ImageZoomCollectionViewCell)
}

class ImageZoomCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    weak var delegate: ImageZoomCollectionViewCellDelegate?
    
    static let reuseIdentifier = "ImageZoomCollectionViewCell"
    
    private var initialTouchPoint: CGPoint = CGPoint(x: 0, y: 0)
    private var originalImageCenter: CGPoint? // 이미지의 중심 위치를 저장
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView(frame: bounds)
        view.minimumZoomScale = 1.0
        view.maximumZoomScale = 5.0
        view.zoomScale = 1.0
        view.delegate = self
        return view
    }()
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        addGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(scrollView)
        scrollView.addSubview(imageView)
    }
    func configure(with image: UIImage) {
        imageView.image = image
        resetZoomScale()
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    private func resetZoomScale() {
        scrollView.zoomScale = 1.0
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        imageView.frame = bounds
        originalImageCenter = imageView.center
    }
    
    private func addGesture() {
        // 아래로 내렸을 때, ViewController를 dismiss시키는 panGesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_ :)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
        
        let doubletap = UITapGestureRecognizer(target: self, action: #selector(doubleTapToZoom))
        doubletap.numberOfTapsRequired = 2
        doubletap.numberOfTouchesRequired = 1
        doubletap.delegate = self
        scrollView.addGestureRecognizer(doubletap)
        
    }
    // 확대 상태에서 panGesture가 가능하도록하는 메서드
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self.window)
        
        switch sender.state {
        case .began:
            initialTouchPoint = touchPoint
        case .changed:
            // 스크롤 뷰의 Zoom Scale이 1.0일 때만 아래로 스크롤하여 닫는 동작을 활성화
            if scrollView.zoomScale == 1.0 {
                let deltaY = touchPoint.y - initialTouchPoint.y
                
                // 이미지를 아래로 드래그 했을 때
                if deltaY > 0 {
                    imageView.center = CGPoint(x: originalImageCenter!.x, y: originalImageCenter!.y + deltaY)
                }
                
                // 이미지를 아래로 드래그 했을 때
                if touchPoint.y - initialTouchPoint.y > 100 {   // 아래로 100포인트 이상 드래그 했을 때
                    delegate?.cellDidRequestDismiss(self)
                }
            }
        case .ended, .cancelled:
            // 드래그가 끝나면 이미지를 원래 위치로 복원
            if scrollView.zoomScale == 1.0 {
                UIView.animate(withDuration: 0.3, animations: {
                    self.imageView.center = self.originalImageCenter ?? CGPoint(x: self.bounds.size.width / 2, y: self.bounds.size.height / 2)
                })
            }
        default:
            break
        }
    }
    
    @objc func doubleTapToZoom(_ gestureRecognizer: UIGestureRecognizer) {
        // 사용자가 탭한 위치 인식
        let pointInView = gestureRecognizer.location(in: imageView)
        
        // 현재 스케일이 최소 스케일이면 확대, 아닌 경우 최소 스케일로 복귀
        let newZoomScale = scrollView.zoomScale == scrollView.minimumZoomScale ? 3.0 : scrollView.minimumZoomScale
        let scrollViewSize = scrollView.bounds.size
        
        // 확대할 영역을 계산
        let width = scrollViewSize.width / newZoomScale
        let height = scrollViewSize.height / newZoomScale
        let x = pointInView.x - (width / 2.0)
        let y = pointInView.y - (height / 2.0)
        
        let rectToZoomTo = CGRect(x: x, y: y, width: width, height: height)
        
        // rectToZoomTo 영역으로 확대
        scrollView.zoom(to: rectToZoomTo, animated: true)
    }
}
