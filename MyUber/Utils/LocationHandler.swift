//
//  LocationHandler.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 18/02/24.
//

import Foundation
import CoreLocation

class LocationHandler: NSObject {
    static let shared = LocationHandler()
    let locationManager: CLLocationManager
    
    private override init() {
        locationManager = CLLocationManager()
        super.init()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationHandler: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }
}


