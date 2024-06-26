//
//  SettingsController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 24/03/24.
//

import UIKit
import FirebaseDatabase

private let reuseIdentifier = "LocationCell"

enum LocationType: Int, CaseIterable, CustomStringConvertible {
    case home
    case work
    
    var description: String {
        switch self {
        case .home: "Home"
        case .work: "Work"
        }
    }
    
    var subtitle: String {
        switch self {
        case .home: "Add Home"
        case .work: "Add Work"
        }
    }
}

protocol SettingsControllerDelegate: AnyObject {
    func updateUser(_ controller: SettingsController)
}

class SettingsController: UITableViewController {
    
    // MARK: -  Properties
    
    weak var delegate: SettingsControllerDelegate?
    var user: User
    
    private let locationManager = LocationHandler.shared.locationManager
    private var userInfoUpdated = false
    
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
        if userInfoUpdated {
            delegate?.updateUser(self)
        }
        
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
    
    private func locationText(for type: LocationType) -> String {
        switch type {
        case .home: user.homeLocation ?? type.subtitle
        case .work: user.workLocation ?? type.subtitle
        }
    }
}

// MARK: - UITableViewDataSource
extension SettingsController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        LocationType.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? LocationCell
        else  { return UITableViewCell() }
        
        guard let type = LocationType(rawValue: indexPath.row) else { return cell }
        cell.titleLabel.text = type.description
        cell.addressLabel.text = locationText(for: type)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SettingsController {
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .backgroundColor
        
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 16)
        title.textColor = .white
        title.text = "Favorites"
        view.addSubview(title)
        title.centerY(inView: view, leftAnchor: view.leftAnchor, paddingLeft: 16)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let type = LocationType(rawValue: indexPath.row),
              let location = locationManager.location else { return }
        let controller = AddLocationController(type: type, location: location)
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        show(nav, sender: true)
    }
}

extension SettingsController: AddLocationControllerDelegate {
    
    func updateLocation(locationString: String, type: LocationType) {
        PassengerService.shared.saveLocation(locationString: locationString, type: type) { [weak self] (err: Error?, ref: DatabaseReference) in
            self?.dismiss(animated: true)
            self?.userInfoUpdated = true
            switch type {
            case .home: self?.user.homeLocation = locationString
            case .work: self?.user.workLocation = locationString
            }
            
            self?.tableView.reloadData()
        }
    }
    
}
