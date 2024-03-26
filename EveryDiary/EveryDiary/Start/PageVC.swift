//
//  PageVC.swift
//  EveryDiary
//
//  Created by eunsung ko on 3/25/24.
//

import UIKit

import SnapKit

class PageVC: UIPageViewController {
    
    var pagesData : [OnboardingModel] = [
        OnboardingModel(descriptionImage: "onBoarding1", descriptionLabel: "오늘의 일기를 기록해보아요"),
        OnboardingModel(descriptionImage: "onBoarding2", descriptionLabel: "일기를 작성하고 불을 밝히세요"),
        OnboardingModel(descriptionImage: "onBoarding3", descriptionLabel: "일기를 채우고 건물을 세우세요"),
        OnboardingModel(descriptionImage: "onBoarding4", descriptionLabel: "캘린더로 기록한 일기를 확인해요"),
        OnboardingModel(descriptionImage: "", descriptionLabel: "로그인하여 일기를 안전하게 보관하세요")
    ]
    
    var pages: [UIViewController] = []
    
    var pageCount: Int {
        return pagesData.count
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        setPageVC()
    }
    
    private func setPageVC() {
        pages = pagesData.map { model -> UIViewController in
            let vc = ContentVC()
            vc.onboardingModel = model
            return vc
        }
        
        if let firstVC = pages.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
    }
}

extension PageVC : UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        let nextIndex = viewControllerIndex + 1
        guard nextIndex < pages.count else {
            return nil
        }
        return pages[nextIndex]
    }
}
