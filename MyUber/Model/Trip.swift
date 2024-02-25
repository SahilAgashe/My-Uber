//
//  Trip.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 25/02/24.
//

import CoreLocation

enum TripState: Int {
    case requested
    case accepted
    case inProgress
    case completed
}

struct Trip {
    var pickupCoordinates: CLLocationCoordinate2D!
    var destinationCoordinates: CLLocationCoordinate2D!
    let passengerUid: String
    var driverUid: String?
    var state: TripState!
}

extension Trip {
    init(passengerUid: String, dictionary: [String: Any]) {
        self.passengerUid = passengerUid
        
        if let pickupCoordinates = dictionary["pickupCoordinates"] as? Array<CLLocationDegrees> {
            self.pickupCoordinates = CLLocationCoordinate2D(latitude: pickupCoordinates[0],
                                                            longitude: pickupCoordinates[1])
        }
        
        if let destinationCoordinates = dictionary["destinationCoordinates"] as? Array<CLLocationDegrees> {
            self.destinationCoordinates = CLLocationCoordinate2D(latitude: destinationCoordinates[0], longitude: destinationCoordinates[1])
        }
        
        self.driverUid = dictionary["driverUid"] as? String ?? ""
        
        if let state = dictionary["state"] as? Int {
            self.state = TripState(rawValue: state)
        }
    }
}


