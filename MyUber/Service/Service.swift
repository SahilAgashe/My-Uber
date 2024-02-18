//
//  Service.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 18/02/24.
//

import Firebase

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")

private let kDebugService = "DEBUG Service"
struct Service {
    private init() {}
    static let shared = Service()
    let currentUid = Auth.auth().currentUser?.uid
    
    func fetchUserData(completion: @escaping(User) -> Void) {
        guard let currentUid else {
            print(kDebugService, "Unable to get current uid!")
            return
        }
        REF_USERS.child(currentUid).observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            guard let dict = snapshot.value as? [String: Any]
            else {
                print(kDebugService, "unable to get snapshot value!")
                return
            }
            
            let user = User(dictionary: dict)
            print(kDebugService, "email => \(user.email)")
            print(kDebugService, "fullname => \(user.fullname)")
            
            completion(user)
        }
    }
}

