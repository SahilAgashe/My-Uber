//
//  SignUpController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 13/02/24.
//

import UIKit
import Firebase

class SignUpController: UIViewController {
    
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
    
    private lazy var fullnameContainerView: UIView = {
        let personImg = UIImage(named: "ic_person_outline_white_2x") ?? UIImage()
        let view = UIView.inputContainerView(image: personImg, textField: fullnameTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private lazy var passwordContainerView: UIView = {
        let lockImg = UIImage(named: "ic_lock_outline_white_2x") ?? UIImage()
        let view = UIView.inputContainerView(image: lockImg, textField: passwordTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private lazy var accountTypeContainerView: UIView = {
        let accountImg = UIImage(named: "ic_account_box_white_2x") ?? UIImage()
        let view = UIView.inputContainerView(image: accountImg, segmentedControl: accountTypeSegmentedControl)
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return view
    }()
    
    private let emailTextField: UITextField = {
        UITextField.textField(withPlaceholder: "Email",
                              isSecureTextEntry: false)
    }()
    
    private let fullnameTextField: UITextField = {
        UITextField.textField(withPlaceholder: "Fullname",
                              isSecureTextEntry: false)
    }()
    
    private let passwordTextField: UITextField = {
        UITextField.textField(withPlaceholder: "Password",
                              isSecureTextEntry: true)
    }()
    
    private let accountTypeSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Rider", "Driver"])
        sc.backgroundColor = .backgroundColor
        sc.tintColor = .init(white: 1, alpha: 0.87)
        sc.selectedSegmentIndex = 0
        return sc
    }()
    
    private lazy var signUpButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return button
    }()
    
    private lazy var alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let dontHaveAccountAttributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor.lightGray]
        let signUpAttributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14), .foregroundColor : UIColor.mainBlueTint]
        
        let attributedTitle = NSMutableAttributedString(string: "Already have an account? ", attributes: dontHaveAccountAttributes)
        attributedTitle.append(NSAttributedString(string: "Log In", attributes: signUpAttributes))
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        
        return button
    }()

    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    
    // MARK: - Selectors
    
    @objc private func handleSignUp() {
        print("DEBUG SignUpController: \(#function)")
        
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              let fullname = fullnameTextField.text
        else {
            print("DEBUG SignUpController: guard let error in \(#function)")
            return
        }
        
        let accountTypeIndex = accountTypeSegmentedControl.selectedSegmentIndex
        
        Auth.auth().createUser(withEmail: email, password: password) { (result: AuthDataResult?, error: Error?) in
            if let error {
                print("DEBUG SignUpController: Error while creating user: \(error)")
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            let values = ["email": email,
                          "fullname:": fullname,
                          "accountType": accountTypeIndex] as [String : Any]
            
            Database.database().reference().child("users").child(uid).updateChildValues(values) { [weak self] (error: Error?, reference: DatabaseReference) in
                if let error {
                    print("DEBUG SignUpController: Error while saving user data in database: \(error)")
                    return
                }
                print("DEBUG SignUpController: Successfully registered and saved user-data!")
                
                /// Deprecated: Accessing rootViewController
                /// let homeControllerWithDeprecatedMethod = UIApplication.shared.keyWindow?.rootViewController as? HomeController
                
                let homeController = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                    .last?.rootViewController as? HomeController
                homeController?.configureUI()
                self?.dismiss(animated: true)
            }
        }
    }
    
    @objc private func handleShowLogin() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helpers
    
    private func configureUI() {
        view.backgroundColor = .backgroundColor
        
        view.addSubview(titleLabel)
        titleLabel.centerX(inView: view)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView,
                                                   fullnameContainerView,
                                                   passwordContainerView,
                                                  accountTypeContainerView,
                                                  signUpButton])
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = 24
        
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor,
                     right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
        
    }
    


}
