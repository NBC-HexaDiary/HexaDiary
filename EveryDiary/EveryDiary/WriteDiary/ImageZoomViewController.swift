//
//  ImageZoomViewController.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/13/24.
//

import UIKit

import SnapKit

class ImageZoomViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    var image: UIImage!
    private var initialTouchPoint: CGPoint = CGPoint(x: 0, y: 0)
    private var originalImageCenter: CGPoint? // 이미지의 중심 위치를 저장
    
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
        addSubViews()
        setLayout()
        addGesture()
        originalImageCenter = view.center
    }
    
    private func addSubViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
    }
    private func setLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        imageView.snp.makeConstraints { make in
            // 이미지의 가로 세로 비율에 맞게 imageView의 높이를 설정
            let imageAspectRitio = image.size.height / image.size.width
            make.center.equalToSuperview()
            make.edges.equalToSuperview()
//            make.width.equalToSuperview()
//            make.height.equalTo(imageView.snp.width).multipliedBy(imageAspectRitio)
        }
    }
    private func addGesture() {
        // 아래로 내렸을 때, ViewController를 dismiss시키는 panGesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_ :)))
        panGesture.delegate = self
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(panGesture)
        
        let doubletap = UITapGestureRecognizer(target: self, action: #selector(doubleTapToZoom))
        doubletap.numberOfTapsRequired = 2
        doubletap.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubletap)
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self.view.window)
        
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
                    self.dismiss(animated: true, completion: nil)
                }
            }
        case .ended, .cancelled:
            // 드래그가 끝나면 이미지를 원래 위치로 복원
            if scrollView.zoomScale == 1.0 {
                UIView.animate(withDuration: 0.3, animations: {
                    self.imageView.center = self.originalImageCenter ?? CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2)
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
        
        // FIXME: 더블탭 했을 때 중앙으로만 확대 되는 메서드
        // 더블탭이 인식되었을 때 호출. 현재 줌 비율에 따라서 다른 반응
//        switch scrollView.zoomScale {
//        case 1.0 ... scrollView.maximumZoomScale: // 확대된 상태인 경우
//            scrollView.setZoomScale(1.0, animated: true)
//        default: // 확대되지 않은 경우
//            scrollView.setZoomScale(4.0, animated: true)
//        }
    }
    
    // 리턴한 view를 핀치 줌이 가능하도록 하는 메서드
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    // 확대 상태에서 panGesture가 가능하도록하는 메서드
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
