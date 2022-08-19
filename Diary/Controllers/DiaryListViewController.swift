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
    private var diaryData: [DiaryData]?
    
    // MARK: - Life Cycle
    
    override func loadView() {
        view = diaryView
        view.backgroundColor = .systemBackground
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSavedData()
//        parseDiaryData()
        configureNavigationItems()
        registerTableView()
        configureDataSource()
        configureDelgate()
    }
    
    // MARK: - Methods
    
//    private func parseDiaryData() {
//        let parsedData: Result<[DiarySampleData], Error> = JSONData.parse(name: AssetData.sample)
//        switch parsedData {
//        case .success(let data):
//            diarySampleData = data
//        case .failure(let error):
//            presentErrorAlert(error)
//        }
//    }
    
//    private func presentErrorAlert(_ error: (Error)) {
//        let errorAlert = UIAlertController(
//            title: AlertMessage.errorAlertTitle,
//            message: error.localizedDescription,
//            preferredStyle: .alert
//        )
//
//        let confirmAction = UIAlertAction(
//            title: AlertMessage.confirmActionTitle,
//            style: .default
//        )
//
//        errorAlert.addAction(confirmAction)
//
//        present(
//            errorAlert,
//            animated: true
//        )
//    }
    
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
        navigationController?.pushViewController(
            DiaryContentsViewController(),
            animated: true
        )
    }
    
    private func registerTableView() {
        let tableView = diaryView.tableView
        
        tableView.register(
            DiaryListCell.self,
            forCellReuseIdentifier: DiaryListCell.identifier
        )
//        tableView.dataSource = dataSource
        // 현재 compositionalLayout이 아닌 flow Layout 방식으로하니 작동됨...
        tableView.dataSource = self
    }
    
    private func configureDataSource() {
        guard let snapshot = configureSnapshot() else {
            return
        }
        
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
                cell.dateLabel.text = diary.createdAt
                cell.contentLabel.text = diary.body
                cell.accessoryType = .disclosureIndicator
                
                return cell
            }
        )
        
        dataSource?.apply(snapshot)
    }
    
    private func configureSnapshot() -> NSDiffableDataSourceSnapshot<Section, DiaryData>? {
        guard let diarySampleData = diaryData else {
            return nil
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, DiaryData>()
        snapshot.appendSections([.main])
        snapshot.appendItems(diarySampleData)
        
        return snapshot
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
            diaryView.tableView.reloadData()
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
            diaryView.tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            diaryView.tableView.deleteRows(at: [indexPath!], with: .fade)
        case .move:
            diaryView.tableView.moveRow(at: indexPath!, to: newIndexPath!)
        case .update:
            diaryView.tableView.reloadRows(at: [indexPath!], with: .fade)
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
        cell.dateLabel.text = diary.createdAt
        cell.contentLabel.text = diary.body
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    
}
