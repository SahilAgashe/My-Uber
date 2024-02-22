//
//  HomeController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 13/02/24.
//

import UIKit
import Firebase
import MapKit

private let reuseIdentifier = "LocationCell"
private let annotationIdentifier = "Driver Annotation"

private let kDebugHomeController = "DEBUG HomeController"
class HomeController: UIViewController {
    
    // MARK: - Properties
    
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    
    private let inputActivationView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    private var searchResults = [MKPlacemark]()
    
    private let locationInputViewHeight: CGFloat = 200
    
    private var user: User? {
        didSet {
            guard let user else { return }
            locationInputView.user = user
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
        enableLocationServices()
    }
    
    // MARK: - API
    
    private func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        Service.shared.fetchUserData(uid: currentUid) { [weak self] user in
            self?.user = user
        }
    }
    
    private func fetchDrivers() {
        guard let location = locationManager.location else { return }
        Service.shared.fetchDrivers(location: location) { [weak self] (driver: User) in
            //print(kDebugHomeController, "Driver fullname => \(driver.fullname)")
            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            
            var driverIsVisible: Bool {
                return self?.mapView.annotations.contains { annotation in
                    guard let driverAnnotation = annotation as? DriverAnnotation else { return false}
                    if driverAnnotation.uid == driver.uid {
                        print(kDebugHomeController, "Position updated for driver => \(driver.fullname)")
                        driverAnnotation.updateAnnotationPosition(withCoordinate: coordinate)
                        return true
                    }
                    return false
                } ?? false
            }
            
            if !driverIsVisible {
                DispatchQueue.main.async {
                    print(kDebugHomeController, "Annotation added for driver => \(driver.fullname)")
                    self?.mapView.addAnnotation(annotation)
                }
            }
        }
    }

    private func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            print("\(kDebugHomeController): current thread is \(Thread.isMainThread)")
            DispatchQueue.main.async { [weak self] in
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                nav.modalTransitionStyle = .flipHorizontal
                self?.present(nav, animated: true)
            }
        } else {
            print("\(kDebugHomeController): Logged User UID => \(Auth.auth().currentUser?.uid ?? "")")
            configure()
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async { [weak self] in
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                nav.modalTransitionStyle = .flipHorizontal
                self?.present(nav, animated: true)
            }
        } catch {
            print("\(kDebugHomeController): Error while signing out!")
        }
    }
    
    // MARK: - Helpers
    
    public func configure() {
        configureUI()
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.fetchUserData()
            self?.fetchDrivers()
        }
    }
    
    private func configureUI() {
        configureMapView()
        
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        
        UIView.animate(withDuration: 2) { [weak self] in
            self?.inputActivationView.alpha = 1
        }
        
        configureTableView()
    }
    
    private func configureMapView() {
        view.addSubview(mapView)
        mapView.anchor(top: view.topAnchor, left: view.leftAnchor,
                       bottom: view.bottomAnchor,right: view.rightAnchor)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
    }
    
    private func configureLocationInputView() {
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor,
                                 right: view.rightAnchor, height: locationInputViewHeight)
        
        locationInputView.alpha = 0
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.locationInputView.alpha = 1
        }) { finished in
            print(kDebugHomeController, "present table view...")
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self else { return }
                self.tableView.frame.origin.y = self.locationInputViewHeight
            }
        }
    }
    
    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        
        let height = view.frame.height - locationInputViewHeight
        tableView.frame = CGRect(x: 0, y: view.frame.height,
                                 width: view.frame.width, height: height)
        view.addSubview(tableView)
    }
}

// MARK: - Map Helper Functions

private extension HomeController {
    func searchBy(naturalLanguageQuery: String, completion: @escaping([MKPlacemark]) -> Void) {
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { (response: MKLocalSearch.Response?, error: Error?) in
            guard let response else {  return }
            
            response.mapItems.forEach { (item: MKMapItem) in
                results.append(item.placemark)
            }
            
            completion(results)
        }
    }
}

// MARK: - MKMapViewDelegate
extension HomeController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            view.image = UIImage(named: "chevron-sign-to-right")
            return view
        }
        return nil
    }
}

// MARK: - Location Services
extension HomeController: CLLocationManagerDelegate {
    func enableLocationServices() {
        locationManager.delegate = self
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print(kDebugHomeController, "Not determined...")
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print(kDebugHomeController, "restricted")
        case .denied:
            print(kDebugHomeController, "denied")
        case .authorizedAlways:
            print(kDebugHomeController, "authorizedAlways")
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print(kDebugHomeController, "authorizedWhenInUse")
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    

    
}

// MARK: - LocationInputActivationViewDelegate
extension HomeController: LocationInputActivationViewDelegate {
    func presentLocationInputView() {
        print(kDebugHomeController, #function)
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
    
}

// MARK: - LocationInputViewDelegate
extension HomeController: LocationInputViewDelegate {
    func executeSearch(query: String) {
        print(kDebugHomeController, "search query is \(query)")
        searchBy(naturalLanguageQuery: query) { [weak self] (placemarks: [MKPlacemark]) in
            self?.searchResults = placemarks
            self?.tableView.reloadData()
        }
    }
    
    func dismissLocationInputView() {
        print(kDebugHomeController, #function)
        
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self else { return }
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
        }) { [weak self] finished in
            self?.locationInputView.removeFromSuperview()
            UIView.animate(withDuration: 0.3) {
                self?.inputActivationView.alpha = 1
            }
        }
    }

}

// MARK: - UITableViewDataSource
extension HomeController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 2 : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? LocationCell else { return UITableViewCell() }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Test"
    }
    
}

// MARK: - UITableViewDelegate
extension HomeController: UITableViewDelegate {
    
}
