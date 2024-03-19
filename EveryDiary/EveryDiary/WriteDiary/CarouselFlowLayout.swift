//
//  CarouselFlowLayout.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/19/24.
//

import UIKit

// imagesCollectionView에 사용될 CarouselFlowLayout(회전목마 스타일)
class CarouselFlowLayout: UICollectionViewFlowLayout {
    let activeDistance: CGFloat = 200   // 활성거리 : 사용자가 스크롤 할 때, 셀이 확대/축소되기 시작하는 지점까지의 거리
    let scale: CGFloat = 0.12            // 스케일 : 셀이 확대되는 정도. 0.12 == 12%
    
    override func prepare() {
        super.prepare()
        scrollDirection = .horizontal
        let horizontalInset = collectionView!.bounds.width * 0.1    // 컬렉션 뷰 양쪽 끝 여백.
        let itemWidth = collectionView!.bounds.width * 0.8          // 셀의 가로 크기
        let itemHeight = collectionView!.bounds.width * 0.8         // 셀의 세로 크기
        minimumLineSpacing = 30                                     // 셀 사이의 최소 간격
        
        sectionInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)   // 섹션 여백
        itemSize = CGSize(width: itemWidth, height: itemHeight)     // 셀 크기 설정
        collectionView?.decelerationRate = .fast                    // 사용자가 스크롤을 멈출 시, 멈추는 속도
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // rect의 레이아웃 속성 획득
        let attributes = super.layoutAttributesForElements(in: rect)
        
        // collectionView의 중앙값을 계산.
        let centerX = collectionView!.contentOffset.x + (collectionView!.bounds.width / 2.0)
        attributes?.forEach { layoutAttribute in
            let distance = abs(layoutAttribute.center.x - centerX)  // 셀과 화면 중앙과의 거리를 계산
            let activeRange = min(distance / activeDistance, 1)     // 활성거리 내에 있는지 확인
            let zoom = 1 + ((1 - activeRange) * scale)              // 스케일 적용
            layoutAttribute.transform = CGAffineTransform(scaleX: zoom, y: zoom)
        }
        return attributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // 스크롤이 발생할 때 레이아웃을 다시 계산하기 위해 true를 반환
        return true
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        // 셀이 스크롤 멈춤 시 중앙에 오도록 계산
        let layoutAttributes = self.layoutAttributesForElements(in: collectionView!.bounds)
        
        // 화면의 중앙을 기준으로 계산
        let center = collectionView!.bounds.size.width / 2
        let proposedContentOffsetCenterOrigin = proposedContentOffset.x + center
        
        var closet = CGFloat.infinity
        var targetOffsetPoint: CGPoint? = nil
        layoutAttributes?.forEach {
            let itemCenter = $0.center.x
            // 중앙에 가장 가까운 셀을 찾아 최종 스크롤 위치를 조정
            if (itemCenter - proposedContentOffsetCenterOrigin).magnitude < closet.magnitude {
                closet = itemCenter - proposedContentOffsetCenterOrigin
                targetOffsetPoint = CGPoint(x: proposedContentOffset.x + closet, y: proposedContentOffset.y)
            }
        }
        return targetOffsetPoint ?? proposedContentOffset
    }
}
