//
//  LoginController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 10/02/24.
//

import UIKit
import Firebase

class LoginController: UIViewController {
    
    // MARK: - Properties
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.textColor = UIColor(white: 1, alpha: 0.8)
        label.font = UIFont(name: "Avenir-Light", size: 36)
        return label
    }()
    
    private lazy var emailContainerView: UIView = {
        let mailImg = UIImage(named: "ic_mail_outline_white_2x") ?? UIImage()
        let view = UIView.inputContainerView(image: mailImg, textField: emailTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private lazy var passwordContainerView: UIView = {
        let lockImg = UIImage(named: "ic_lock_outline_white_2x") ?? UIImage()
        let view = UIView.inputContainerView(image: lockImg, textField: passwordTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private let emailTextField: UITextField = {
        UITextField.textField(withPlaceholder: "Email",
                              isSecureTextEntry: false)
    }()
    
    private let passwordTextField: UITextField = {
        UITextField.textField(withPlaceholder: "Password",
                              isSecureTextEntry: true)
    }()
    
    private lazy var loginButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        return button
    }()

    private lazy var dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let dontHaveAccountAttributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.lightGray]
        let signUpAttributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14), .foregroundColor : UIColor.mainBlueTint]
        
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account? ", attributes: dontHaveAccountAttributes)
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: signUpAttributes))
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(handleShowSignUP), for: .touchUpInside)
        
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        .lightContent
//    }
    
    // MARK: - Selectors
    
    @objc private func handleLogin() {
        print("DEBUG LoginController: \(#function)")
        
        guard let email = emailTextField.text,
              let password = passwordTextField.text else {
            print("DEBUG LoginController: guard let error in \(#function)")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result: AuthDataResult?, error: Error?) in
            if let error {
                print("DEBUG LoginController: Failed to log user in with error: \(error.localizedDescription)")
                return
            }
            print("DEBUG LoginController: Successfully logged user in...")
            
            /// Deprecated: Accessing rootViewController
            /// let homeControllerWithDeprecatedMethod = UIApplication.shared.keyWindow?.rootViewController as? HomeController
            
            /// Note:- last scene-key-window is main keyWindow
            let homeController = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .last?.rootViewController as? HomeController
            homeController?.configure()
            self?.dismiss(animated: true)
        }
        
    }
    
    @objc private func handleShowSignUP() {
        let controller = SignUpController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: - Helpers
    
    private func configureUI() {
        configureNavigationBar()
        view.backgroundColor = .backgroundColor
        
        view.addSubview(titleLabel)
        titleLabel.centerX(inView: view)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView,
                                                   passwordContainerView,
                                                   loginButton])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 16
        
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor,
                     right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.centerX(inView: view)
        dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
    }
    
    private func configureNavigationBar() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
    }

}
