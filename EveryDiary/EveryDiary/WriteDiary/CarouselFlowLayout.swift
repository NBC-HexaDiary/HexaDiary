//
//  CarouselFlowLayout.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/19/24.
//

import UIKit

// imagesCollectionView에 사용될 CarouselFlowLayout(회전목마 스타일)을 구현하기 위한 커스텀 FlowLayout 클래스
class CarouselFlowLayout: UICollectionViewFlowLayout {
    let activeDistance: CGFloat = 200    // 활성거리 : 사용자가 스크롤 할 때, 셀이 확대/축소되기 시작하는 지점까지의 거리
    let scale: CGFloat = 0.12            // 스케일 : 셀이 확대되는 정도. 0.12 == 12%
    
    // collectionView cell의 레이아웃 기본설정
    override func prepare() {
        super.prepare()
        scrollDirection = .horizontal
        let horizontalInset = collectionView!.bounds.width * 0.1    // 컬렉션 뷰 양쪽 끝 여백.
        let itemWidth = collectionView!.bounds.width * 0.8          // 셀의 가로 크기
        let itemHeight = collectionView!.bounds.width * 0.8         // 셀의 세로 크기
        minimumLineSpacing = 30                                     // 셀 사이의 최소 간격
        
        sectionInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)   // 섹션 여백 좌우를 horizontalInset만큼 설정
        itemSize = CGSize(width: itemWidth, height: itemHeight)     // 셀 크기 설정
        collectionView?.decelerationRate = .fast                    // 사용자가 스크롤을 멈출 시, 멈추는 속도
    }
    
    // 스크롤 중이거나 레이아웃이 변경될 때 셀의 레이아웃 속성을 계산
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // rect의 레이아웃 속성 획득
        let attributes = super.layoutAttributesForElements(in: rect)
        
        // collectionView의 X축 중앙값을 계산.
        let centerX = collectionView!.contentOffset.x + (collectionView!.bounds.width / 2.0)
        attributes?.forEach { layoutAttribute in
            // 각 셀의 중앙과 컬렉션 뷰의 중앙과의 거리를 계산
            // 거리를 활성거리로 나누어 스케일을 계산. 거리가 활성거리보다 가까울 때만 cell 확대
            let distance = abs(layoutAttribute.center.x - centerX)  // 셀과 화면 중앙과의 거리를 계산
            let activeRange = min(distance / activeDistance, 1)     // 활성거리 내에 있는지 확인
            let zoom = 1 + ((1 - activeRange) * scale)              // 스케일 적용
            // 계산된 스케일을 셀의 변환에 적용. 셀이 실제로 확대 축소 되도록 transform
            layoutAttribute.transform = CGAffineTransform(scaleX: zoom, y: zoom)
        }
        return attributes
    }
    
    // 스크롤이 발생하거나 view의 크기가 변경될 때마다 레이아웃을 다시 계산해야한다는 것을 명시적으로 표현
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true     // 스크롤이 발생할 때 항상 레이아웃을 다시 계산하기 위해 true를 반환
    }
    
    // 사용자가 스크롤을 멈췄을 때 셀이 화면 중앙에 위치하도록 최종 스크롤 위치를 조정.
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        // 현재 화면에 보이는 셀의 레이아웃 속성을 획득
        let layoutAttributes = self.layoutAttributesForElements(in: collectionView!.bounds)
        
        // 화면의 중앙을 기준으로 계산
        let center = collectionView!.bounds.size.width / 2
        // proposedContentOffset에서 화면 중앙까지의 거리를 계산하는 변수
        let proposedContentOffsetCenterOrigin = proposedContentOffset.x + center
        
        var closet = CGFloat.infinity               // 가장 가까운 셀을 찾기 위한 변수
        var targetOffsetPoint: CGPoint? = nil       // 최종 스크롤 오프셋을 저장할 변수
        
        // 모든 셀의 레이아웃 속성을 순회. 화면 중앙에 가장 가까운 셀 추적
        layoutAttributes?.forEach {
            let itemCenter = $0.center.x
            // 중앙에 가장 가까운 셀을 찾아 최종 스크롤 위치를 조정
            if (itemCenter - proposedContentOffsetCenterOrigin).magnitude < closet.magnitude {
                closet = itemCenter - proposedContentOffsetCenterOrigin
                // 최종 스크롤 오프셋을 계산. 사용자가 스크롤을 멈추면 적용.
                targetOffsetPoint = CGPoint(x: proposedContentOffset.x + closet, y: proposedContentOffset.y)
            }
        }
        // 계산된 최종 스크롤 오프셋을 반환. 계산이 안되면 proposedContentOffset 그대로 사용.
        return targetOffsetPoint ?? proposedContentOffset
    }
}
