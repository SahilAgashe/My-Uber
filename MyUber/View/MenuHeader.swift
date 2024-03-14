//
//  MenuHeader.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 13/03/24.
//

import UIKit

class MenuHeader: UIView {
    
    // MARK: - Properties
    
    var user: User? {
        didSet {
            fullnameLabel.text = user?.fullname
            emailLabel.text = user?.email
        }
    }
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    private let fullnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.text = "Sahil Agashe"
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.text = "test@gmail.com"
        return label
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureUI()
    }
    
    // MARK: - Selectors
    
    // MARK: - Helpers
    private func configureUI() {
        backgroundColor = .backgroundColor
        
        addSubview(profileImageView)
        profileImageView.anchor(top: safeAreaLayoutGuide.topAnchor, left: leftAnchor,
                                paddingTop: 4, paddingLeft: 12,
                                width: 64, height: 64)
        profileImageView.layer.cornerRadius = 64 / 2
        
        let stack = UIStackView(arrangedSubviews: [fullnameLabel, emailLabel])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        
        addSubview(stack)
        stack.centerY(inView: profileImageView,
                      leftAnchor: profileImageView.rightAnchor,
                      paddingLeft: 12)
    }
}
