//
//  LoginController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 10/02/24.
//

import UIKit

class LoginController: UIViewController {
    
    // MARK: - Properties
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "UBER"
        label.textColor = UIColor(white: 1, alpha: 0.8)
        label.font = UIFont(name: "Avenir-Light", size: 36)
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .init(red: 25/255, green: 25/255, blue: 25/255, alpha: 1)
        
        view.addSubview(titleLabel)
        titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    
}
