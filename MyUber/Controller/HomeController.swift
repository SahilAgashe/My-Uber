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

private enum ActionButtonConfiguration {
    case showMenu
    case dismissActionView
    
    init() {
        self = .showMenu
    }
}

private let kDebugHomeController = "DEBUG HomeController"
class HomeController: UIViewController {
    // MARK: - Properties
    
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    
    private let inputActivationView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let rideActionView = RideActionView()
    private let tableView = UITableView()
    private var searchResults = [MKPlacemark]()
    private final let locationInputViewHeight: CGFloat = 200
    private final let rideActionViewHeight: CGFloat = 300
    private var actionButtonConfig = ActionButtonConfiguration()
    private var route: MKRoute?
    
    private var user: User? {
        didSet {
            guard let user else { return }
            locationInputView.user = user
        }
    }
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        let menuImg = UIImage(named: "baseline_menu_black_36dp")?.withRenderingMode(.alwaysOriginal)
        button.setImage(menuImg, for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
        enableLocationServices()
    }
    
    // MARK: - Selectors
    
    @objc private func actionButtonPressed() {
        print(kDebugHomeController, #function)
        
        switch actionButtonConfig {
        case .showMenu:
            print(kDebugHomeController, "actionButtonConfig => show menu")
        case .dismissActionView:
            print(kDebugHomeController, "actionButtonConfig => dismiss action view")
            removeAnnotationsAndOverlays()
            
            // zoom enough to show all annotations
            mapView.showAnnotations(mapView.annotations, animated: true)
            
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.inputActivationView.alpha = 1
                self?.configureActionButton(config: .showMenu)
                self?.animateRideActionView(shouldShow: false)
            }
        }
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
        configureRideActionView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,
                            paddingTop: 16, paddingLeft: 20, width: 30, height: 30)
        
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
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
    
    private func configureRideActionView() {
        view.addSubview(rideActionView)
        rideActionView.frame = CGRect(x: 0, y: view.frame.height,
                                      width: view.frame.width, height: rideActionViewHeight)
        rideActionView.delegate = self
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
    
    private func configureActionButton(config: ActionButtonConfiguration) {
        switch config {
        case .showMenu:
            let menuImg = UIImage(named: "baseline_menu_black_36dp")?.withRenderingMode(.alwaysOriginal)
            actionButton.setImage(menuImg, for: .normal)
            actionButtonConfig = .showMenu
        case .dismissActionView:
            let backArrow = UIImage(named: "baseline_arrow_back_black_36dp")?.withRenderingMode(.alwaysOriginal)
            actionButton.setImage(backArrow, for: .normal)
            actionButtonConfig = .dismissActionView
        }
    }
    
    private func dismissLocationView(completion: ((Bool) -> Void)? = nil) {
        print(kDebugHomeController, #function)
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self else { return }
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
        }, completion: completion)
    }
    
    private func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil) {
        let yOrigin = shouldShow ? view.frame.height - rideActionViewHeight : view.frame.height
        
        if shouldShow {
            guard let destination else { return }
            rideActionView.destination = destination
        }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.rideActionView.frame.origin.y = yOrigin
        }
    }
    
}

// MARK: - MapView Helper Functions

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
    
    func generatePolyline(toDestination destination: MKMapItem) {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { [weak self] (response: MKDirections.Response?, error: Error?) in
            guard let response else { return }
            self?.route = response.routes[0]
            guard let polyline = self?.route?.polyline else { return  }
            self?.mapView.addOverlay(polyline)
        }
    }
    
    func removeAnnotationsAndOverlays() {
        mapView.annotations.forEach { annotation in
            if let anno = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            }
        }
        
        if !mapView.overlays.isEmpty {
            mapView.removeOverlay(mapView.overlays[0])
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route {
            let polyline = route.polyline
            let lineRenderer: MKPolylineRenderer = MKPolylineRenderer(overlay: polyline)
            lineRenderer.strokeColor = .mainBlueTint
            lineRenderer.lineWidth = 4
            return lineRenderer
        }
        return MKOverlayRenderer()
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
        dismissLocationView { [weak self] _ in
            UIView.animate(withDuration: 0.5) {
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
        if indexPath.section == 1 {
            cell.placemark = searchResults[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Test"
    }
    
}

// MARK: - UITableViewDelegate
extension HomeController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlacemark = searchResults[indexPath.row]
        
        configureActionButton(config: .dismissActionView)
        
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestination: destination)
        
        dismissLocationView { [weak self] finished in
            guard let self else { return }
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedPlacemark.coordinate
            self.mapView.addAnnotation(annotation)
            self.mapView.selectAnnotation(annotation, animated: true)
            
            // zoom enough to show only annotations including MKUserLocation and MKPointAnnotation
            let annotations = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self)})
            self.mapView.zoomToFit(annotations: annotations)
            
            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark)
        }
    }
}

extension HomeController: RideActionViewDelegate {
    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager.location?.coordinate,
              let destinationCoordinates = view.destination?.coordinate
        else { return }
        
        Service.shared.uploadTrip(pickupCoordinates, destinationCoordinates) { (error: Error?, ref: DatabaseReference) in
            if let error {
                print(kDebugHomeController, "Error while uploading trip: \(error.localizedDescription)")
                return
            }
            print(kDebugHomeController, "Trip uploaded successfully!")
        }
    }
}
