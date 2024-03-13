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

private enum AnnotationType: String {
    case pickup
    case destination
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
            print(kDebugHomeController, "User name is \(user?.fullname ?? "Unable to get user full name!")")
            locationInputView.user = user
            if user?.accountType == .passenger {
                fetchDrivers()
                configureLocationInputActivationView()
                observeCurrentTrip()
            } else {
                print(kDebugHomeController, "User is driver...!")
                observeTrips()
            }
        }
    }
    
    private var trip: Trip? {
        didSet {
            guard let user = self.user else { return }
            if user.accountType == .driver {
                print(kDebugHomeController, "Show pickup controller!")
                guard let trip else { return }
                let controller = PickupController(trip: trip)
                controller.delegate = self
                present(controller, animated: true)
            } else {
                print(kDebugHomeController, "Show ride action view for accepted trip..")
            }
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(kDebugHomeController, #function)
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
    
    // MARK: - Passenger API
    
    private func observeCurrentTrip() {
        PassengerService.shared.observeCurrentTrip { [weak self] trip in
            self?.trip = trip
            guard let state = trip.state else { return }
            guard let driverUid = trip.driverUid else { return }
            
            switch state {
            case .requested:
                break
                
            case .accepted:
                self?.shouldPresentLoadingView(false)
                self?.removeAnnotationsAndOverlays()
                self?.zoomForActiveTrip(withDriverUid: driverUid)
                Service.shared.fetchUserData(uid: driverUid) { [weak self] driver in
                    self?.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
                }
                
            case .driverArrived:
                self?.rideActionView.config = .driverArrived
                
            case .inProgress:
                self?.rideActionView.config = .tripInProgress
            case .arrivedAtDestination:
                print(kDebugHomeController, "Handle arrive at destination!")
                self?.rideActionView.config = .endTrip
            case .completed:
                PassengerService.shared.deleteTrip { (err: Error?, ref: DatabaseReference) in
                    self?.animateRideActionView(shouldShow: false)
                    self?.centerMapOnUserLocation()
                    self?.configureActionButton(config: .showMenu)
                    self?.inputActivationView.alpha = 1
                    self?.presentAlertController(withTitle: "Trip Completed", message: "We hope you enjoyed your trip!")
                }
            }
        }
    }
    
    private func startTrip() {
        guard let trip = self.trip else { return }
        DriverService.shared.updateTripState(trip: trip, state: .inProgress) { [weak self] err, ref in
            self?.rideActionView.config = .tripInProgress
            self?.removeAnnotationsAndOverlays()
            self?.mapView.addAnnotationAndSelect(forCoordinate: trip.destinationCoordinates)
            
            self?.setCustomRegion(withType: .destination, coordinates: trip.destinationCoordinates)
            
            let placemark = MKPlacemark(coordinate: trip.destinationCoordinates)
            let mapItem = MKMapItem(placemark: placemark)
            self?.generatePolyline(toDestination: mapItem)
            
            if let annotations = self?.mapView.annotations {
                self?.mapView.zoomToFit(annotations: annotations)
            }
            
        }
    }
    
    /// fetch drivers if user-accountType is passenger.
    private func fetchDrivers() {
        guard let location = locationManager.location else { return }
        PassengerService.shared.fetchDrivers(location: location) { [weak self] (driver: User) in
            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            
            var driverIsVisible: Bool {
                return self?.mapView.annotations.contains { annotation in
                    guard let driverAnnotation = annotation as? DriverAnnotation else { return false}
                    if driverAnnotation.uid == driver.uid {
                        print(kDebugHomeController, "Position updated for driver => \(driver.fullname)")
                        driverAnnotation.updateAnnotationPosition(withCoordinate: coordinate)
                        self?.zoomForActiveTrip(withDriverUid: driver.uid)
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

    // MARK: - Driver API
    private func observeTrips() {
        DriverService.shared.observeTrips { trip in
            self.trip = trip
        }
    }
    
    private func observeCancelledTrip(trip: Trip) {
        DriverService.shared.observeTripCancelled(trip: trip) { [weak self] in
            guard let self else { return }
            self.removeAnnotationsAndOverlays()
            self.animateRideActionView(shouldShow: false)
            self.centerMapOnUserLocation()
            self.presentAlertController(withTitle: "Oops!",message: "The passenger has decided to cancel this ride. Press OK to continue.")
        }

    }
    
    // MARK: - Shared API
    
    private func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        Service.shared.fetchUserData(uid: currentUid) { [weak self] user in
            self?.user = user
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
        }
    }
    
    private func configureUI() {
        configureMapView()
        configureRideActionView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,
                            paddingTop: 16, paddingLeft: 20, width: 30, height: 30)
        
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
    
    private func configureLocationInputActivationView() {
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        
        UIView.animate(withDuration: 2) { [weak self] in
            self?.inputActivationView.alpha = 1
        }
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
    
    private func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil,
                                       config: RideActionViewConfiguration? = nil, user: User? = nil) {
        let yOrigin = shouldShow ? view.frame.height - rideActionViewHeight : view.frame.height
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.rideActionView.frame.origin.y = yOrigin
        }
        
        if shouldShow {
            guard let config else { return }
            
            if let destination {
                rideActionView.destination = destination
            }
            
            if let user {
                rideActionView.user = user
            }
            
            rideActionView.config = config
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
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: 2000,
                                        longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    func setCustomRegion(withType type: AnnotationType, coordinates: CLLocationCoordinate2D) {
        let region = CLCircularRegion(center: coordinates, radius: 25, identifier: type.rawValue)
        locationManager.startMonitoring(for: region)
        
        print(kDebugHomeController, #function, "region => \(region)")
    }
    
    func zoomForActiveTrip(withDriverUid uid: String) {
        var annotations = [MKAnnotation]()
        mapView.annotations.forEach({ (annotation: MKAnnotation) in
            if let anno = annotation as? DriverAnnotation {
                if anno.uid == uid {
                    annotations.append(anno)
                }
            }
            
            if let userAnno = annotation as? MKUserLocation {
                annotations.append(userAnno)
            }
        })
        print("DEBUG: Annotations array is \(annotations)")
        mapView.zoomToFit(annotations: annotations)
    }
}

// MARK: - MKMapViewDelegate
extension HomeController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let user, user.accountType == .driver,
              let location = userLocation.location else { return }
        DriverService.shared.updateDriverLocation(location: location)
    }
    
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

// MARK: - CLLocationManagerDelegate
extension HomeController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if region.identifier == AnnotationType.pickup.rawValue {
            print(kDebugHomeController, "didStartMonitoringFor pick-up region \(region)")
        }
        
        if region.identifier == AnnotationType.destination.rawValue {
            print(kDebugHomeController, "didStartMonitoringFor destination region \(region)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let trip else { return }
        if region.identifier == AnnotationType.pickup.rawValue {
            print(kDebugHomeController, "didEnterRegion pickup region \(region)")
            DriverService.shared.updateTripState(trip: trip, state: .driverArrived) { [weak self] err, ref in
                self?.rideActionView.config = .pickupPassenger
            }
        }
        
        if region.identifier == AnnotationType.destination.rawValue {
            print(kDebugHomeController, "didEnterRegion destination region \(region)")
            DriverService.shared.updateTripState(trip: trip, state: .arrivedAtDestination) { [weak self] err, ref in
                self?.rideActionView.config = .endTrip
            }
        }
    }
    
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
            mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)
            
            // zoom enough to show only annotations including MKUserLocation and MKPointAnnotation
            let annotations = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self)})
            self.mapView.zoomToFit(annotations: annotations)
            
            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
        }
    }
}

// MARK: - RideActionViewDelegate
extension HomeController: RideActionViewDelegate {
    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager.location?.coordinate,
              let destinationCoordinates = view.destination?.coordinate
        else { return }
        
        shouldPresentLoadingView(true, message: "Finding you a ride..")
        
        PassengerService.shared.uploadTrip(pickupCoordinates, destinationCoordinates) { (error: Error?, ref: DatabaseReference) in
            if let error {
                print(kDebugHomeController, "Error while uploading trip: \(error.localizedDescription)")
                return
            }
            print(kDebugHomeController, "Trip uploaded successfully!")
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self else { return }
                self.rideActionView.frame.origin.y = self.view.frame.height
            }
        }
        
    }
    
    func cancelTrip() {
        print(kDebugHomeController, "Cancelling trip!")
        
        PassengerService.shared.deleteTrip { [weak self] (error: Error?, ref: DatabaseReference) in
            if let error {
                print(kDebugHomeController, "Error deleting trip: \(error.localizedDescription)")
                return
            }
            
            self?.centerMapOnUserLocation()
            self?.animateRideActionView(shouldShow: false)
            self?.removeAnnotationsAndOverlays()
            
            let menuImg = UIImage(named: "baseline_menu_black_36dp")?.withRenderingMode(.alwaysOriginal)
            self?.actionButton.setImage(menuImg, for: .normal)
            self?.actionButtonConfig = .showMenu
            
            self?.inputActivationView.alpha = 1
        }
    }
    
    func pickupPassenger() {
        startTrip()
    }
    
    func dropOffPassenger() {
        guard let trip else { return }
        DriverService.shared.updateTripState(trip: trip, state: .completed) { [weak self](err: Error?, ref: DatabaseReference) in
            self?.removeAnnotationsAndOverlays()
            self?.centerMapOnUserLocation()
            self?.animateRideActionView(shouldShow: false)
        }
    }
}

// MARK: - PickupControllerDelegate
extension HomeController: PickupControllerDelegate {
    func didAcceptTrip(_ trip: Trip) {
        print(kDebugHomeController, #function)
        self.trip = trip
        
        mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
        
        setCustomRegion(withType: .pickup, coordinates: trip.pickupCoordinates)
        
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestination: mapItem)
        
        mapView.zoomToFit(annotations: mapView.annotations)
                
        observeCancelledTrip(trip: trip)
        
        self.dismiss(animated: true) { [weak self] in
            Service.shared.fetchUserData(uid: trip.passengerUid) { passenger in
                self?.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
            }
        }
    }
}
