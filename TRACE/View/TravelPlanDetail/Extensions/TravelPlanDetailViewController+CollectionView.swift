//
//  TravelPlanDetailViewController+CollectionView.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - UICollectionViewDataSource
extension TravelPlanDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalDays
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TravelDayCell", for: indexPath) as? TravelDayCell else {
            return UICollectionViewCell()
        }

        let day = indexPath.item + 1 // 1-based
        let isSelected = indexPath.item == selectedDayIndex
        cell.configure(day: day, isSelected: isSelected)

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension TravelPlanDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.frame.width
        let spacing: CGFloat = 8
        let numberOfItemsToShow = min(totalDays, 5) // 최대 5개까지 한 화면에 표시
        let totalSpacing = spacing * CGFloat(numberOfItemsToShow - 1)
        let itemWidth = (availableWidth - totalSpacing) / CGFloat(numberOfItemsToShow)

        return CGSize(width: max(itemWidth, 80), height: 60) // 최소 너비 80
    }
}

