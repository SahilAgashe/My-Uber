//
//  LocationInputView.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 17/02/24.
//

import UIKit

protocol LocationInputViewDelegate: AnyObject {
    func dismissLocationInputView()
}

private let kDebugLocationInputView = "DEBUG LocationInputView"
class LocationInputView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: LocationInputViewDelegate?
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "baseline_arrow_back_black_36dp")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBackTapped), for: .touchUpInside)
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
    
    @objc private func handleBackTapped() {
        print(kDebugLocationInputView, #function)
        delegate?.dismissLocationInputView()
    }
    
    // MARK: - Helpers
    
    private func configureUI() {
        backgroundColor = .white
        
        addShadow()
        
        addSubview(backButton)
        backButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: 44,
                          paddingLeft: 12, width: 24, height: 25)
    }
}
