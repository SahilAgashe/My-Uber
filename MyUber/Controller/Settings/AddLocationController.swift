//
//  AddLocationController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 28/03/24.
//

import UIKit
import MapKit

private let reuseIdentifier = "Cell"

protocol AddLocationControllerDelegate: AnyObject {
    func updateLocation(locationString: String, type: LocationType)
}

private let kDebugAddLocationController = "DEBUG AddLocationController"
class AddLocationController: UITableViewController {
    
    // MARK: - Properties
    
    weak var delegate: AddLocationControllerDelegate?
    
    private let searchBar = UISearchBar()
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults = [MKLocalSearchCompletion]() {
        didSet { tableView.reloadData() }
    }
    
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
        tableView.backgroundColor = .white
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
        let result = searchResults[indexPath.row]
        
        var contentConfig = cell.defaultContentConfiguration()
        contentConfig.text = result.title
        contentConfig.secondaryText = result.subtitle
        cell.contentConfiguration = contentConfig
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AddLocationController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        let title = result.title
        let subtitle = result.subtitle
        let locationString = title + " " + subtitle
        delegate?.updateLocation(locationString: locationString, type: type)
    }
}

// MARK: - UISearchBarDelegate
extension AddLocationController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // whenever searchCompleter.queryFragment updates , it will call completerDidUpdateResults(_:)
        searchCompleter.queryFragment = searchText
    }
    
    
}

// MARK: - MKLocalSearchCompleterDelegate
extension AddLocationController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }
}
