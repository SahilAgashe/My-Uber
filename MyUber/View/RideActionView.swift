//
//  RideActionView.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 24/02/24.
//

import UIKit

private let kDebugRideActionView = "DEBUG RideActionView"
class RideActionView: UIView {
    
    // MARK: - Properties
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.text = "Vinoba Nagar, Tumsar"
        label.textAlignment = .center
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        label.text = "At Pachine Road, Vinoba Nagar, Tumsar"
        label.textAlignment = .center
        return label
    }()
    
    private lazy var infoView: UIView = {
       let view = UIView()
        view.backgroundColor = .black
        
        let label = UILabel()
        label.font = .systemFont(ofSize: 30)
        label.text = "X"
        label.textColor = .white
        
        view.addSubview(label)
        label.center(inView: view)
        
        return view
    }()
    
    private let uberXLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.text = "Uber X"
        label.textAlignment = .center
        return label
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .black
        button.setTitle("CONFIRM UBERX", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        return button
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
    
    @objc private func actionButtonPressed() {
        print(kDebugRideActionView, #function)
    }
    
    // MARK: - Helpers
    
    private func configureUI() {
        backgroundColor = .white
        addShadow()
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        
        addSubview(stack)
        stack.centerX(inView: self)
        stack.anchor(top: topAnchor, paddingTop: 12)
        
        addSubview(infoView)
        infoView.centerX(inView: self)
        infoView.anchor(top: stack.bottomAnchor, paddingTop: 16)
        infoView.setDimensions(height: 60, width: 60)
        infoView.layer.cornerRadius = 60 / 2
        
        addSubview(uberXLabel)
        uberXLabel.anchor(top: infoView.bottomAnchor, paddingTop: 8)
        uberXLabel.centerX(inView: self)
        
        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        addSubview(separatorView)
        separatorView.anchor(top: uberXLabel.bottomAnchor, left: leftAnchor,
                             right: rightAnchor, paddingTop: 4, height: 0.75)
        
        addSubview(actionButton)
        actionButton.anchor(left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor,
                            right: rightAnchor, paddingLeft: 12, paddingBottom: 24,
                            paddingRight: 12, height: 50)
    }
    
    
}
