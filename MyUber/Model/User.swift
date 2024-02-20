//
//  User.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 18/02/24.
//

import CoreLocation

struct User {
    let fullname: String
    let email: String
    let accountType: Int
    var location: CLLocation?
}


extension User {
    init(dictionary: [String: Any]) {
        fullname = dictionary["fullname"] as? String ?? ""
        email = dictionary["email"] as? String ?? ""
        accountType = dictionary["accountType"] as? Int ?? 0
    }
}
