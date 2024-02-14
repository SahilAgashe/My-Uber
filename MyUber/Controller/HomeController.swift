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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
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
        mapView.frame = view.frame
        view.addSubview(mapView)
    }
}
