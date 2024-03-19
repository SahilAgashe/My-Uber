//
//  MenuController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 13/03/24.
//

import UIKit

private let reuseIdentifier = "MenuCell"

private enum MenuOption: Int, CaseIterable, CustomStringConvertible {
    
    case yourTrips
    case settings
    case logout
    
    var description: String {
        switch self {
        case .yourTrips : "Your Trips"
        case .settings: "Settings"
        case .logout: "Log Out"
        }
    }
}

class MenuController: UITableViewController {
    
    // MARK: - Properties
    
    private let user: User
    
    private lazy var menuHeader: MenuHeader = {
        var frame = CGRect(origin: .zero, size: .zero)
        frame.size.height = 140
        let view = MenuHeader(user: user, frame: frame)
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
    }
    
    // MARK: - Selectors
    
    // MARK: - Helpers
    private func configureTableView() {
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = 60
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.tableHeaderView = menuHeader
    }
    
}

extension MenuController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        MenuOption.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        guard let option = MenuOption(rawValue: indexPath.row) else { return UITableViewCell() }
        cell.textLabel?.text = option.description
        
        return cell
    }
}
