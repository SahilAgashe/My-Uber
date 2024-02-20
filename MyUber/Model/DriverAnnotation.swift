//
//  DriverAnnotation.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 20/02/24.
//

import MapKit

class DriverAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let uid: String
    
    init(uid: String, coordinate: CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }
}