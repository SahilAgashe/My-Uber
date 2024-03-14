//
//  ContainerController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 13/03/24.
//

import UIKit
import Firebase

private let kDebugContainerController = "DEBUG ContainerController"
class ContainerController: UIViewController {
    
    // MARK: - Properties
    
    private let homeController = HomeController()
    private let menuController = MenuController()
    private var isExpanded = false
    
    private var user: User? {
        didSet {
            guard let user else { return }
            homeController.user = user
            configureMenuController(withUser: user)
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHomeController()
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.fetchUserData()
        }
    }
    
    // MARK: - Selectors
    
    // MARK: - API
    
    private func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        Service.shared.fetchUserData(uid: currentUid) { [weak self] user in
            self?.user = user
        }
    }
    
    // MARK: - Helpers
    
    private func configureHomeController() {
        addChild(homeController)
        homeController.didMove(toParent: self)
        view.addSubview(homeController.view)
        homeController.delegate = self
    }
    
    private func configureMenuController(withUser user: User) {
        addChild(menuController)
        menuController.didMove(toParent: self)
        menuController.view.frame = view.frame
        view.insertSubview(menuController.view, at: 0)
        menuController.user = user
    }
    
    private func animateMenu(shouldExpand: Bool) {
        if shouldExpand {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
                self.homeController.view.frame.origin.x = self.view.frame.width - 80
            }
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
                self.homeController.view.frame.origin.x = 0
            }
        }
    }
}

extension ContainerController: HomeControllerDelegate {
    func handleMenuToggle() {
        print(kDebugContainerController, #function)
        isExpanded.toggle()
        animateMenu(shouldExpand: isExpanded)
    }
}
