//
//  UIViewController+Extension.swift
//  Diary
//
//  Created by Finnn, 수꿍 on 2022/08/23.
//

import UIKit

extension UIViewController {
    func presentErrorAlert(_ error: (Error)) {
        let errorAlert = UIAlertController(
            title: AlertMessage.errorAlertTitle,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        let confirmAction = UIAlertAction(
            title: AlertMessage.confirmActionTitle,
            style: .default
        )
        
        errorAlert.addAction(confirmAction)
        
        present(
            errorAlert,
            animated: true
        )
    }
}