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
        let view = UIView()
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_mail_outline_white_2x")
        imageView.alpha = 0.87
        view.addSubview(imageView)
        imageView.centerY(inView: view)
        imageView.anchor(left: view.leftAnchor, paddingLeft: 8, width: 24, height: 24)
        
        view.addSubview(emailTextField)
        emailTextField.centerY(inView: view)
        emailTextField.anchor(left: imageView.rightAnchor, bottom: view.bottomAnchor, 
                              right: view.rightAnchor, paddingLeft: 8, paddingBottom: 8)
        
        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        view.addSubview(separatorView)
        separatorView.anchor(left: view.leftAnchor, bottom: view.bottomAnchor,
                             right: view.rightAnchor, paddingLeft: 8, height: 0.75)
        
        return view
    }()
    
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = .white
        tf.keyboardAppearance = .dark
        tf.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [.foregroundColor : UIColor.lightGray])
        return tf
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .init(red: 25/255, green: 25/255, blue: 25/255, alpha: 1)
        
        view.addSubview(titleLabel)
        titleLabel.centerX(inView: view)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        
        view.addSubview(emailContainerView)
        emailContainerView.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingRight: 0 ,height: 50)
        
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    
}
