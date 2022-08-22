//
//  Diary - DiaryListViewController.swift
//  Created by Finnn, 수꿍 
//  Copyright © yagom. All rights reserved.
// 

import UIKit
import CoreData

enum Section {
    case main
}

final class DiaryListViewController: UIViewController {
    
    // MARK: - Properties

    
    var fetchResultsController: NSFetchedResultsController<Diary>!

    let viewContext: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        return appDelegate.persistentContainer.viewContext
    }()
    
    private let diaryView = DiaryListView()
    private var dataSource: UITableViewDiffableDataSource<Section, DiaryData>?
    private var snapShot = NSDiffableDataSourceSnapshot<Section, DiaryData>()
    
    var asd: Date = Date()
    var isDeleted: Bool = false
    
    // MARK: - Life Cycle
    
    override func loadView() {
        view = diaryView
        view.backgroundColor = .systemBackground
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        loadSavedData()
        configureNavigationItems()
        registerTableView()
        
        configureDelgate()
        
//        guard let diary = fetchResultsController.sections?[0].objects as? [Diary] else {
//            return
//        }
//        
//        diary.forEach {
//            print($0.createdAt)
//        }
//        
//        CoreDataManager().update(data: diary[1])
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isDeleted {
            CoreDataManager.shared.delete(createdAt: asd)
        }
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        dataSource?.apply(snapShot)
//    }
    
    // MARK: - Methods
    
    private func configureNavigationItems() {
        title = NavigationItem.diaryTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: SystemImage.plus),
            style: .plain,
            target: self,
            action: #selector(plusButtonTapped)
        )
    }
    
    @objc private func plusButtonTapped() {
        moveToDiaryContentsViewController()
    }
    
    private func moveToDiaryContentsViewController() {
        let nextVC = DiaryContentsViewController()

        nextVC.isEditingMemo = false

        navigationController?.pushViewController(
            nextVC,
            animated: true
        )
    }
    
    private func registerTableView() {
        let tableView = diaryView.tableView
        
        tableView.register(
            DiaryListCell.self,
            forCellReuseIdentifier: DiaryListCell.identifier
        )
        tableView.dataSource = dataSource
        // 현재 compositionalLayout이 아닌 flow Layout 방식으로하니 작동됨...
//        tableView.dataSource = self
    }
    
    private func configureDataSource() {
        configureSnapshot()
        
        let tableView = diaryView.tableView
        
        dataSource = UITableViewDiffableDataSource<Section, DiaryData>(
            tableView: tableView,
            cellProvider: { tableView, indexPath, item in
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: DiaryListCell.identifier,
                    for: indexPath
                ) as? DiaryListCell else {
                    return nil
                }
                
//                cell.titleLabel.text = item.title
//                cell.dateLabel.text = item.createdAt.localizedString
//                cell.contentLabel.text = item.body
//                cell.accessoryType = .disclosureIndicator
                
                let diary = self.fetchResultsController.object(at: indexPath)
                cell.titleLabel.text = diary.title
                cell.dateLabel.text = diary.createdAt?.localizedString
                cell.bodyLabel.text = diary.body
                cell.accessoryType = .disclosureIndicator
                
                return cell
            }
        )
    }
    
    private func configureSnapshot() {
        snapShot.appendSections([.main])
    }
    
    private func configureDelgate() {
        diaryView.tableView.delegate = self
    }
    
    func loadSavedData() {
        if fetchResultsController == nil {
            let request = NSFetchRequest<Diary>(entityName: "Diary")
            let sort = NSSortDescriptor(key: "createdAt", ascending: false)
            request.sortDescriptors = [sort]
            request.fetchBatchSize = 20
            
            fetchResultsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil)
            fetchResultsController.delegate = self
        }
        
        do {
            try fetchResultsController.performFetch()
            
            guard let diary = fetchResultsController.sections?[0].objects as? [Diary] else {
                return
            }
            
            let convertedDiary = diary.map { diary in
                DiaryData(title: diary.title!, body: diary.body!, createdAt: diary.createdAt!)
            }
            
            snapShot.appendItems(convertedDiary)
            dataSource?.apply(snapShot)
            
        } catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - UITableViewDelegate

extension DiaryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(
            at: indexPath,
            animated: true
        )
        
        let diary = fetchResultsController.object(at: indexPath)
        
        
        let nextVC = DiaryContentsViewController()
        nextVC.diary = diary
        nextVC.diaryView = diaryView
        nextVC.isEditingMemo = true
        
        nextVC.delegate = self
        
        navigationController?.pushViewController(nextVC, animated: true)
    }
}

extension DiaryListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        diaryView.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        guard let newDiary = anObject as? Diary else {
            return
        }
        let diaryData = DiaryData(title: newDiary.title!, body: newDiary.body!, createdAt: newDiary.createdAt!)
        
        switch type {
        case .insert:
                
            if snapShot.numberOfItems == .zero {
                snapShot.appendItems([diaryData])
            } else {
                let 새로운인덱스 = IndexPath(row: newIndexPath!.row + 1, section: 0)
                let lastObject = self.fetchResultsController.object(at: 새로운인덱스)
                let lastDiaryData = DiaryData(title: lastObject.title!, body: lastObject.body!, createdAt: lastObject.createdAt!)
                
                snapShot.insertItems([diaryData], beforeItem: lastDiaryData)
            }
            
        case .delete:
            snapShot.deleteItems([diaryData])
        case .move:
            diaryView.tableView.moveRow(at: indexPath!, to: newIndexPath!)
        case .update:
            snapShot.reloadSections([.main])
        @unknown default:
            break
        }
        
        dataSource?.apply(snapShot)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        diaryView.tableView.endUpdates()
    }
}

extension DiaryListViewController: SendUpdateProtocol {
    func sendUpdated() {
        click()
    }
    
    @objc private func click() {
          do {
              try fetchResultsController.performFetch()

              diaryView.tableView.reloadData()
          }
          catch (let err) {
              print(err.localizedDescription)
          }
        }
}

extension DiaryListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            let sectionInfo = fetchResultsController.sections![section]
            return sectionInfo.numberOfObjects
        }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DiaryListCell.identifier, for: indexPath) as? DiaryListCell else {
            return UITableViewCell()
        }

        let diary = self.fetchResultsController.object(at: indexPath)
        cell.titleLabel.text = diary.title
        cell.dateLabel.text = diary.createdAt?.localizedString
        cell.bodyLabel.text = diary.body
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard let diaryData = self.dataSource?.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { action, view, completion in
//            let alert = UIAlertController(title: "진짜요?", message: "정말로 삭제하시겠어요?", preferredStyle: .alert)
//            let cancelAction = UIAlertAction(title: "취소", style: .cancel)
//            let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { _ in
//                self.navigationController?.popViewController(animated: true)
                
                CoreDataManager.shared.delete(createdAt: diaryData.createdAt)
//            }

//            alert.addAction(cancelAction)
//            alert.addAction(deleteAction)
//
//            self.present(alert, animated: true)
//            completion(true)
        }
        let shareAction = UIContextualAction(style: .normal, title: "Share") { action, view, completion in
            let activityViewController = UIActivityViewController(activityItems: [diaryData.title+"\n"+diaryData.body], applicationActivities: nil)
            self.present(activityViewController, animated: true)
            completion(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash.fill")
        shareAction.backgroundColor = .systemBlue
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        
        let swipeActionCongifuration = UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
        swipeActionCongifuration.performsFirstActionWithFullSwipe = false
        return swipeActionCongifuration
    }
}
