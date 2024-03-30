//
//  AddLocationController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 28/03/24.
//

import UIKit
import MapKit

private let reuseIdentifier = "Cell"

private let kDebugAddLocationController = "DEBUG AddLocationController"
class AddLocationController: UITableViewController {
    
    // MARK: - Properties
    
    private let searchBar = UISearchBar()
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults = [MKLocalSearchCompletion]()
    
    private let type: LocationType
    private let location: CLLocation
    
    // MARK: - Init
    
    init(type: LocationType, location: CLLocation) {
        self.type = type
        self.location = location
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureSearchBar()
        configureSearchCompleter()
        
        print(kDebugAddLocationController, "Type => \(type.description)")
        print(kDebugAddLocationController, "Location => \(location)")
    }
    
    // MARK: - Helpers
    
    private func configureTableView() {
        tableView.backgroundColor = .cyan
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        tableView.addShadow()
    }
    
    private func configureSearchBar() {
        searchBar.sizeToFit()
        searchBar.delegate = self
        navigationItem.titleView = searchBar
    }
    
    private func configureSearchCompleter() {
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        searchCompleter.region = region
        searchCompleter.delegate = self
    }
    
}

// MARK: - UITableViewDataSource
extension AddLocationController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        return cell
    }
}

// MARK: - UISearchBarDelegate
extension AddLocationController: UISearchBarDelegate {
    
}

// MARK: -
extension AddLocationController: MKLocalSearchCompleterDelegate {
    
}
