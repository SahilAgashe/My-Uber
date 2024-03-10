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
let REF_TRIPS = DB_REF.child("trips")

private let kDebugService = "DEBUG Service"
struct Service {
    private init() {}
    static let shared = Service()
    
    func fetchUserData(uid: String, completion: @escaping(User) -> Void) {
        REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            guard let dict = snapshot.value as? [String: Any]
            else {
                print(kDebugService, "unable to get snapshot value!")
                return
            }
            let user = User(uid: snapshot.key, dictionary: dict)
            completion(user)
        }
    }
    
    /// fetchDrivers will fetch all driver within 50 radius of given location.
    func fetchDrivers(location: CLLocation, completion: @escaping(User) -> Void) {
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        
        // here, observe method used to listen for data changes at a particular location. This is the primary way to read data from the Firebase Database. Your block will be triggered for the initial data and again whenever the data changes.
        /// if we update coordinates of a driver location in firebase , then this method will be called!
        REF_DRIVER_LOCATIONS.observe(.value) { (snapshot: DataSnapshot)  in
            print(kDebugService, #function)
            geofire.query(at: location, withRadius: 50).observe(.keyEntered) { (uid: String, location: CLLocation) in
                fetchUserData(uid: uid) { user in
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
            }
        }
    }
    
    func uploadTrip(_ pickupCoordinates: CLLocationCoordinate2D, _ destinationCoordinates: CLLocationCoordinate2D, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let pickupArray = [pickupCoordinates.latitude, pickupCoordinates.longitude]
        let destinationArray = [destinationCoordinates.latitude, destinationCoordinates.longitude]
        
        let values = ["pickupCoordinates": pickupArray,
                      "destinationCoordinates": destinationArray,
                      "state": TripState.requested.rawValue] as [String : Any]
        
        /// updateChildValues will update value for key if key already exists, otherwise will create new key-value pair.
        REF_TRIPS.child(uid).updateChildValues(values, withCompletionBlock: completion)
    }
    
    /// fetch trips and observe when new trip is added.
    func observeTrips(completion: @escaping(Trip) -> Void) {
        REF_TRIPS.observe(.childAdded) { (snapshot: DataSnapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
    
    func observeTripCancelled( trip: Trip, completion: @escaping() -> Void) {
        REF_TRIPS.child(trip.passengerUid).observeSingleEvent(of: .childRemoved) { (snapshot: DataSnapshot) in
            completion()
        }
    }
    
    func acceptTrip(trip: Trip, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let values = ["driverUid": uid,
                      "state": TripState.accepted.rawValue] as [String : Any]
        
        /// updateChildValues will update value for key if key already exists in dictionary, otherwise will append new key-value pair in dictionary.
        REF_TRIPS.child(trip.passengerUid).updateChildValues(values, withCompletionBlock: completion)
    }
    
    func observeCurrentTrip(completion: @escaping(Trip) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        REF_TRIPS.child(uid).observe(.value) { (snapshot: DataSnapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
    
    func deleteTrip(completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        REF_TRIPS.child(uid).removeValue(completionBlock: completion)
    }
    
    func updateDriverLocation(location: CLLocation) {
        print(kDebugService, #function)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        geofire.setLocation(location, forKey: uid)
    }
    
    func updateTripState(trip: Trip, state: TripState,
                         completion: @escaping(Error?, DatabaseReference) -> Void) {
        REF_TRIPS.child(trip.passengerUid).child("state").setValue(state.rawValue, withCompletionBlock: completion)
        
        if state == .completed {
            REF_TRIPS.child(trip.passengerUid).removeAllObservers()
        }
    }
}

