//
//  Service.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 18/02/24.
//

import Firebase
import GeoFire

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-locations")

private let kDebugService = "DEBUG Service"
struct Service {
    private init() {}
    static let shared = Service()
    let currentUid = Auth.auth().currentUser?.uid
    
    func fetchUserData(uid: String, completion: @escaping(User) -> Void) {
//        guard let currentUid else {
//            print(kDebugService, "Unable to get current uid!")
//            return
//        }
        REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            guard let dict = snapshot.value as? [String: Any]
            else {
                print(kDebugService, "unable to get snapshot value!")
                return
            }
            
            let user = User(dictionary: dict)
            //print(kDebugService, "email => \(user.email)")
            //print(kDebugService, "fullname => \(user.fullname)")
            
            completion(user)
        }
    }
    
    func fetchDrivers(location: CLLocation, completion: @escaping(User) -> Void) {
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        
        REF_DRIVER_LOCATIONS.observe(.value) { (snapshot: DataSnapshot)  in
            geofire.query(at: location, withRadius: 50).observe(.keyEntered) { (uid: String, location: CLLocation) in
                //print(kDebugService, "UID => \(uid), location => \(location)")
                fetchUserData(uid: uid) { user in
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
            }
        }
    }
}

