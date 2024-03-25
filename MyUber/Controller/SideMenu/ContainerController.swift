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
    private let blackView = UIView()
    private lazy var xOrigin = view.frame.width - 80
    
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
        checkIfUserIsLoggedIn()
    }
    
    override var prefersStatusBarHidden: Bool {
        isExpanded
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .slide
    }
    
    // MARK: - Selectors
    
    @objc private func dismissMenu() {
        print(kDebugContainerController, #function)
        isExpanded = false
        animateMenu(shouldExpand: isExpanded)
    }
    
    // MARK: - API
    
    private func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            print("\(kDebugContainerController): current thread is \(Thread.isMainThread)")
            DispatchQueue.main.async { [weak self] in
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                nav.modalTransitionStyle = .flipHorizontal
                self?.present(nav, animated: true)
            }
        } else {
            print("\(kDebugContainerController): Logged User UID => \(Auth.auth().currentUser?.uid ?? "")")
            configure()
        }
    }
    
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
    
    public func configure() {
        configureHomeController()
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.fetchUserData()
        }
    }
    
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
        configureBlackView()
    }
    
    private func configureBlackView() {
        blackView.frame = CGRect(x: xOrigin, y: 0, width: 80, height: self.view.frame.height)
        blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        blackView.alpha = 0
        view.addSubview(blackView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
        blackView.addGestureRecognizer(tap)
    }
    
    private func animateMenu(shouldExpand: Bool, completion: ((Bool) -> Void)? = nil) {
        if shouldExpand {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: { [weak self] in
                guard let self else { return }
                self.homeController.view.frame.origin.x = xOrigin
                self.blackView.alpha = 1
            })
        } else {
            self.blackView.alpha = 0
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: { [weak self] in
                guard let self else { return }
                self.homeController.view.frame.origin.x = 0
            }, completion: completion)
        }
        
        animateStatusBar()
    }
    
    private func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) { [weak self] in
            self?.setNeedsStatusBarAppearanceUpdate()
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
            case .settings:
                guard let user = self?.user else { return }
                let controller = SettingsController(user: user)
                let nav = UINavigationController(rootViewController: controller)
                guard let self else { return }
                nav.modalPresentationStyle = .fullScreen
                show(nav, sender: self)
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
