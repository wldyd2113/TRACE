//
//  UIViewController+Keyboard.swift
//  TRACE
//
//  Created by 차지용 on 10/3/25.
//

import UIKit

extension UIViewController {

    /// 키보드 해제 기능을 활성화합니다.
    /// - 화면 탭 시 키보드 해제
    /// - Return 키 누를 시 키보드 해제
    func setupKeyboardDismissal() {
        setupTapToDismissKeyboard()
        setupReturnKeyDismissal()
    }

    /// 화면을 탭했을 때 키보드를 해제하는 제스처를 추가합니다.
    private func setupTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    /// Return 키를 눌렀을 때 키보드를 해제하도록 설정합니다.
    private func setupReturnKeyDismissal() {
        // 현재 뷰의 모든 UITextField에 대해 delegate 설정
        configureTextFieldsForKeyboardDismissal(in: view)
    }

    /// 재귀적으로 모든 UITextField를 찾아서 설정합니다.
    private func configureTextFieldsForKeyboardDismissal(in view: UIView) {
        for subview in view.subviews {
            if let searchBar = subview as? UISearchBar {
                // UISearchBar는 자체적으로 delegate를 가지므로 건드리지 않음
                // SearchBar의 Return 키 타입을 Search로 설정
                if #available(iOS 13.0, *) {
                    searchBar.searchTextField.returnKeyType = .search
                } else {
                    // iOS 13 미만에서는 하위 뷰에서 UITextField 찾아서 설정
                    for subView in searchBar.subviews {
                        for textField in subView.subviews {
                            if let textField = textField as? UITextField {
                                textField.returnKeyType = .search
                            }
                        }
                    }
                }
                // SearchBar 내부는 처리하지 않음
                continue
            } else if let textField = subview as? UITextField {
                // UISearchBar 내부의 textField는 건드리지 않음
                if !isTextFieldInSearchBar(textField) {
                    // 기존 delegate가 없는 경우에만 설정
                    if textField.delegate == nil {
                        // KeyboardDismissalDelegate를 생성하여 설정
                        textField.delegate = KeyboardDismissalDelegate.shared
                    }
                    // Return 키 타입을 Done으로 설정
                    if textField.returnKeyType == .default {
                        textField.returnKeyType = .done
                    }
                }
            } else if let textView = subview as? UITextView {
                // UITextView의 경우 Done 버튼 추가
                addDoneButtonToTextView(textView)
            } else {
                // 하위 뷰들도 재귀적으로 검색
                configureTextFieldsForKeyboardDismissal(in: subview)
            }
        }
    }

    /// TextField가 UISearchBar 내부에 있는지 확인합니다.
    private func isTextFieldInSearchBar(_ textField: UITextField) -> Bool {
        var superview = textField.superview
        while superview != nil {
            if superview is UISearchBar {
                return true
            }
            superview = superview?.superview
        }
        return false
    }

    /// UITextView에 Done 버튼이 있는 toolbar를 추가합니다.
    private func addDoneButtonToTextView(_ textView: UITextView) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(
            title: "완료",
            style: .done,
            target: self,
            action: #selector(dismissKeyboard)
        )
        doneButton.tintColor = .skyBlue

        toolbar.items = [flexSpace, doneButton]
        textView.inputAccessoryView = toolbar
    }

    /// 키보드를 해제합니다.
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - KeyboardDismissalDelegate
class KeyboardDismissalDelegate: NSObject, UITextFieldDelegate {
    static let shared = KeyboardDismissalDelegate()

    private override init() {
        super.init()
    }

    /// Return 키를 눌렀을 때 키보드를 해제합니다.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}