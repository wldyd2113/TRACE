//
//  TravelPlanShowViewController+Delegates.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit

// MARK: - UICollectionViewDataSource
extension TravelPlanShowViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalDays
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TravelDayCell.identifier,
            for: indexPath
        ) as? TravelDayCell else {
            return UICollectionViewCell()
        }

        let dayNumber = indexPath.item + 1
        let isSelected = indexPath.item == selectedDayIndex

        cell.configure(day: dayNumber, isSelected: isSelected)

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension TravelPlanShowViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectDay(at: indexPath.item)
        print("📅 CollectionView에서 선택됨: \(indexPath.item + 1)일차")
    }

    func selectDay(at index: Int) {
        let previousIndex = selectedDayIndex
        selectedDayIndex = index
        currentDay = index + 1

        // ViewModel에 일차 선택 알림
        daySelectedSubject?.onNext(currentDay)

        // CollectionView 업데이트
        DispatchQueue.main.async { [weak self] in
            self?.dateCollectionView.reloadItems(at: [
                IndexPath(item: previousIndex, section: 0),
                IndexPath(item: index, section: 0)
            ])
        }

        print("📅 일차 선택됨: \(currentDay)일차 (index: \(index))")
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension TravelPlanShowViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 60)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

// MARK: - UISearchBarDelegate
extension TravelPlanShowViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        guard let query = searchBar.text, !query.isEmpty else {
            print("⚠️ 빈 검색어")
            return
        }

        // 편집 모드에서만 검색 실행
        if isEditMode {
            performManualSearch(query: query)
        }

        print("🔍 검색바에서 검색: \(query)")
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // 편집 모드가 아닐 때는 즉시 편집 종료
        if !isEditMode {
            searchBar.resignFirstResponder()
            print("🔒 읽기 전용 모드에서는 검색할 수 없습니다")
            return
        }

        print("🔍 검색바 편집 시작")
    }
}
