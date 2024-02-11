//
//  LoginController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 10/02/24.
//

import UIKit

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

    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .init(red: 25/255, green: 25/255, blue: 25/255, alpha: 1)
        
        view.addSubview(titleLabel)
        titleLabel.centerX(inView: view)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView, passwordContainerView])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 16
        
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor,
                     right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

}
