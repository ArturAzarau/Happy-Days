//
//  ViewController.swift
//  Happy Days
//
//  Created by Артур Азаров on 14.02.2018.
//  Copyright © 2018 Артур Азаров. All rights reserved.
//

import UIKit

final class PermissionsViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var helpLabel: UILabel!
    
    // MARK: - Properties
    
    let permissionsManager = PermissionsManager()
    
    // MARK: - Actions
    @IBAction func requestPermissions(_ sender: UIButton) {
        permissionsManager.requestPermissions(errorHandler: { (error) in
            DispatchQueue.main.async { [weak self] in
                self?.helpLabel.text = error.localizedDescription
            }
        }) {
            DispatchQueue.main.async { [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }
}
