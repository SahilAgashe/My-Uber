//
//  User.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 18/02/24.
//

import CoreLocation

enum AccountType: Int {
    case passenger
    case driver
}

struct User {
    let uid: String
    let fullname: String
    let email: String
    var accountType: AccountType!
    var location: CLLocation?
    var homeLocation: String?
    var workLocation: String?
}


extension User {
    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        fullname = dictionary["fullname"] as? String ?? ""
        email = dictionary["email"] as? String ?? ""
        
        if let index = dictionary["accountType"] as? Int {
            accountType = AccountType(rawValue: index)
        }
        
        if let home = dictionary["homeLocation"] as? String {
            homeLocation = home
        }
        
        if let work = dictionary["workLocation"] as? String {
            workLocation = work
        }
    }
}
