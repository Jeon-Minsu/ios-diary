//
//  DiaryContentsViewController.swift
//  Diary
//
//  Created by Finnn, 수꿍 on 2022/08/16.
//

import UIKit
import CoreData

final class DiaryContentsViewController: UIViewController {
    
    // MARK: - Properties
    
    var isEditingMemo: Bool = false
    var diary: Diary?
    var diaryView: DiaryListView?
    var delegate: SendUpdateProtocol?
    
    private let diaryContentView = DiaryContentView()
    
    // MARK: Life Cycle
    
    override func loadView() {
        view = diaryContentView
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItems()
        configureNotificationCenter()
//        diaryContentView.textView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        diaryContentView.textView.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        guard !diaryContentView.textView.text.isEmpty else {
            return
        }
        
        
        
        let fullText = diaryContentView.textView.text ?? ""
        
        var title: String = fullText
        var body: String = ""
        
        if fullText.contains("\n") {
            let lineBreakIndex = fullText.firstIndex(of: "\n")
            let firstLineBreakIndexInt = lineBreakIndex!.utf16Offset(in: fullText)
            let titleRange = NSMakeRange(0, firstLineBreakIndexInt)
            title = (fullText as NSString).substring(with: titleRange)
            
            let bodyRange = NSMakeRange(firstLineBreakIndexInt + 1, fullText.count - title.count - 1)
            body = (fullText as NSString).substring(with: bodyRange)
        }
        
        
        if isEditingMemo {
            guard let createdAt = diary?.createdAt else {
                return
            }
            CoreDataManager.shared.update(title: title, body: body, createdAt: createdAt)
        } else {
            CoreDataManager.shared.saveDiary(title: title, body: body, createdAt: Date())
        }
        
        
    }
    
    // MARK: - Methods
    
    private func configureNavigationItems() {
        title = NavigationItem.diaryTitle
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: SystemImage.ellipsisCircle),
            style: .plain,
            target: self,
            action: #selector(sharedButtonTapped)
        )
    }
    
    @objc private func sharedButtonTapped() {
        let actionSheet = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .actionSheet)
        
        let shareAction = UIAlertAction(title: "Share...",
                                        style: .default) { _ in
            
            let items = [UIImage(systemName: "pencil") as Any, self.diaryContentView.textView.text!]
            let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            self.present(activityViewController, animated: true)
        }
        
        let deleteAction = UIAlertAction(title: "Delete",
                                         style: .destructive) { _ in
            
            let alert = UIAlertController(title: "진짜요?", message: "정말로 삭제하시겠어요?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "취소", style: .cancel)
            let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { _ in
                self.navigationController?.popViewController(animated: true)
                CoreDataManager.shared.delete(self.diary!)
            }
            
            alert.addAction(cancelAction)
            alert.addAction(deleteAction)
            
            self.present(alert, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)
        
        actionSheet.addAction(shareAction)
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet,
                animated: true,
                completion: nil)
    }
    
    private func configureUI() {

        title = diary?.createdAt == nil
            ? Date().localizedString
            : diary?.createdAt!.localizedString
        
        guard let diaryTitle = diary?.title,
              let diaryBody = diary?.body else {
            diaryContentView.textView.text = ""
            return
        }
        
        diaryContentView.textView.text = "\(diaryTitle)\n\(diaryBody)"
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

//extension DiaryContentsViewController: NSFetchedResultsControllerDelegate {
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        if type == .insert {
//            DispatchQueue.main.async {
////                chatcollectionView.insertItems(at: [newIndexPath!])
////                self.diaryView?.tableView.insertRows(at: [newIndexPath!], with: .fade)
//
//                guard let newDiaryData = anObject as? Diary else {
//                    return
//                }
//
//                let diary = DiaryData(title: newDiaryData.title!, body: newDiaryData.body!, createdAt: newDiaryData.createdAt!)
//
//
////                snapShot.appendItems([diary])
////                dataSource?.apply(snapShot)
//            }
//
//            delegate?.sendUpdated()
//
//        }
//    }
//}

protocol SendUpdateProtocol: AnyObject {
    func sendUpdated()
}
//
//extension DiaryContentsViewController: UITextViewDelegate {
////    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
////        print(text)
////        return true
////
////        let heading = "Bills or Taxes once paid through the payment gateway shall not be refunded other then in the following circumstances:"
////        let content = "\n \n 1. Multiple times debiting of Consumer Card/Bank Account due to ticnical error excluding Payment Gateway charges would be refunded to the consumer with in 1 week after submitting complaint form. \n \n 2. Consumers account being debited with excess amount in single transaction due to tecnical error will be deducted in next month transaction. \n \n 3. Due to technical error, payment being charged on the consumers Card/Bank Account but the Bill is unsuccessful."
//
////        let attributedText = NSMutableAttributedString(string: heading, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)])
////
////        attributedText.append(NSAttributedString(string: content, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15), NSAttributedString.Key.foregroundColor: UIColor.blue]))
////
////        textView.attributedText = attributedText
////    }
//
//    func textViewDidChange(_ textView: UITextView) {
//        print(textView.text)
//
////        let firstEnterIndex = textView.text.firstIndex(of: "\n")
////        let title = textView.text.
//
//
//        let fullText = textView.text ?? ""
//        let range = (fullText as NSString).range(of: "\n")
//        print(range.description)
//        let attributedString = NSMutableAttributedString(string: fullText)
//        attributedString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .title1), range: range)
//        textView.attributedText = attributedString
//
//
////        diaryContentView.textView.attributedText = attributedString
//    }
//}
