//
//  HomeController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 13/02/24.
//

import UIKit
import Firebase
import MapKit

private let kDebugHomeController = "DEBUG HomeController"
class HomeController: UIViewController {
    
    // MARK: - Properties
    
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
        enableLocationServices()
    }
    
    // MARK: - API

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
            configureUI()
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("\(kDebugHomeController): Error while signing out!")
        }
    }
    
    // MARK: - Helpers
    
    public func configureUI() {
        configureMapView()
    }
    
    private func configureMapView() {
        mapView.frame = view.frame
        view.addSubview(mapView)
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
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
    
    // MARK: - CLLocationManagerDelegate Methods
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }
    
}
