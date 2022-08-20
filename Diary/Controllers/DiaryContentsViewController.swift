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

        title = Date().localizedString
        configureNotificationCenter()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        let newDiaryData = DiaryData(
            title: "제목",
            body: diaryContentView.textView.text,
            createdAt: Date())
        CoreDataManager().saveDiary(data: newDiaryData)
    }
    
    // MARK: - Methods
    
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


