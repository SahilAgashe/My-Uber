//
//  MenuController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 13/03/24.
//

import UIKit

private let reuseIdentifier = "MenuCell"
class MenuController: UITableViewController {
    
    // MARK: - Properties
    
    private lazy var menuHeader: MenuHeader = {
        var frame = CGRect(origin: .zero, size: .zero)
        frame.size.height = 140
        let view = MenuHeader(frame: frame)
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //tableView.backgroundColor = .white
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
        3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.textLabel?.text = " Menu Option"
        return cell
    }
}
