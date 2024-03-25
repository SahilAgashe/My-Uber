//
//  SettingsController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 24/03/24.
//

import UIKit

private let reuseIdentifier = "LocationCell"

class SettingsController: UITableViewController {
    
    // MARK: -  Properties
    
    private let user: User
    
    private lazy var infoHeader: UserInfoHeader = {
        let view = UserInfoHeader(user: user, frame: .zero)
        view.frame.size.height = 100
        return view
    }()
    
    // MARK: - Init
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureNavigationBar()
    }
    
    // MARK: Selectors
    
    @objc private func handleDismissal() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    private func configureTableView() {
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        tableView.backgroundColor = .white
        tableView.rowHeight = 60
        tableView.tableHeaderView = infoHeader
    }
    
    private func configureNavigationBar() {
        // navigationBar
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .backgroundColor
        navigationController?.navigationBar.barStyle = .black
        
        // navigationItem
        navigationItem.title = "Settings"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "baseline_clear_white_36pt_2x")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismissal))
    }
}
