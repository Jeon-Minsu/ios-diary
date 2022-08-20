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
    private var diaryData: [DiaryData]?
    
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
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        diaryView.tableView.reloadData()
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
        switch type {
        case .insert:
            
            guard let newDiaryData = anObject as? Diary else {
                return
            }
            
            let diary = DiaryData(title: newDiaryData.title!, body: newDiaryData.body!, createdAt: newDiaryData.createdAt!)
            
            
            if snapShot.numberOfItems == .zero {
                snapShot.appendItems([diary])
            } else {
                let 새로운인덱스 = IndexPath(row: newIndexPath!.row + 1, section: 0)
                let lastObject = self.fetchResultsController.object(at: 새로운인덱스)
                let lastDiaryData = DiaryData(title: lastObject.title!, body: lastObject.body!, createdAt: lastObject.createdAt!)
                
                snapShot.insertItems([diary], beforeItem: lastDiaryData)
            }
            
            dataSource?.apply(snapShot)
            
        case .delete:
            diaryView.tableView.deleteRows(at: [indexPath!], with: .fade)
        case .move:
            diaryView.tableView.moveRow(at: indexPath!, to: newIndexPath!)
        case .update:
//            diaryView.tableView.reloadRows(at: [indexPath!], with: .fade)
            snapShot.reloadSections([.main])
            dataSource?.apply(snapShot)
        @unknown default:
            break
        }
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
          catch let err{
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
}
