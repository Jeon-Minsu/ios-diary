//
//  DiaryContentsViewController.swift
//  Diary
//
//  Created by Finnn, 수꿍 on 2022/08/16.
//

import UIKit

final class DiaryContentsViewController: UIViewController {
    
    // MARK: - Properties
    
    private let diaryContentView = DiaryContentView()
    var diary: Diary?
    var isEditingMemo: Bool = false
    
    // MARK: Life Cycle
    
    override func loadView() {
        view = diaryContentView
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        configureNotificationCenter()
    }
    
    // MARK: - Methods
    
    private func configureUI() {
        guard let diaryTitle = diary?.title,
              let diaryBody = diary?.body,
              let diaryCreatedAt = diary?.createdAt else {
            title = Date().localizedString
            return
        }
        
        title = diaryCreatedAt.localizedString
        
        let titleAttributedString = NSMutableAttributedString(
            string: diaryTitle,
            attributes: [.font: UIFont.preferredFont(forTextStyle: .title1)]
        )
        let lineBreakAttributedString = NSMutableAttributedString(string: "\n")
        let bodyAttributedString = NSMutableAttributedString(
            string: diaryBody,
            attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
        )
        
        let diaryContentText = NSMutableAttributedString()
        diaryContentText.append(titleAttributedString)
        diaryContentText.append(lineBreakAttributedString)
        diaryContentText.append(bodyAttributedString)
        diaryContentView.textView.attributedText = diaryContentText
    }
    
    private func configureNotificationCenter() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let contentInset = UIEdgeInsets(top: 0.0,
                                        left: 0.0,
                                        bottom: keyboardFrame.size.height,
                                        right: 0.0)
        
        diaryContentView.textView.contentInset = contentInset
        diaryContentView.textView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func keyboardWillHide() {
        let contentInset = UIEdgeInsets.zero
        
        diaryContentView.textView.contentInset = contentInset
        diaryContentView.textView.scrollIndicatorInsets = contentInset
    }
}
