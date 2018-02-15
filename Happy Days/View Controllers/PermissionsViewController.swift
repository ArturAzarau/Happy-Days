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
        permissionsManager.requestPermissions { (error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.helpLabel.text = error.localizedDescription
                }
                return
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.dismiss(animated: true)
                }
            }
        }
    }
}
