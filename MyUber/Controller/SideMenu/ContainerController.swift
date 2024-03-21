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
    private var menuController: MenuController!
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
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async { [weak self] in
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                nav.modalTransitionStyle = .flipHorizontal
                self?.present(nav, animated: true)
            }
        } catch {
            print("\(kDebugContainerController): Error while signing out!")
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
        menuController = MenuController(user: user)
        addChild(menuController)
        menuController.didMove(toParent: self)
        menuController.view.frame = view.frame
        view.insertSubview(menuController.view, at: 0)
        menuController.delegate = self
    }
    
    private func animateMenu(shouldExpand: Bool, completion: ((Bool) -> Void)? = nil) {
        if shouldExpand {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = self.view.frame.width - 80
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = 0
            }, completion: completion)
        }
    }
}

// MARK: - HomeControllerDelegate

extension ContainerController: HomeControllerDelegate {
    func handleMenuToggle() {
        print(kDebugContainerController, #function)
        isExpanded.toggle()
        animateMenu(shouldExpand: isExpanded)
    }
}

// MARK: - MenuControllerDelegate

extension ContainerController: MenuControllerDelegate {
    func didSelect(option: MenuOption) {
        isExpanded.toggle()
        animateMenu(shouldExpand: isExpanded) { [weak self] _ in
            switch option {
            case .yourTrips: break
            case .settings: break
            case .logout:
                let alert = UIAlertController(title: nil, message: "Are you sure you want to logout?", preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
                    self?.signOut()
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self?.show(alert, sender: self)
            }
        }
    }
}
