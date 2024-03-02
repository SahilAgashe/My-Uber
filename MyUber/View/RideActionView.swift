//
//  RideActionView.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 24/02/24.
//

import UIKit
import MapKit

protocol RideActionViewDelegate: AnyObject {
    func uploadTrip(_ view: RideActionView)
}

enum RideActionViewConfiguration {
    case requestRide
    case tripAccepted
    case pickupPassenger
    case tripInProgress
    case endTrip
    
    init() {
        self = .requestRide
    }
}

enum ButtonAction: CustomStringConvertible {
    case requestRide
    case cancel
    case getDirections
    case pickup
    case dropOff
    
    var description: String {
        switch self {
        case .requestRide: return "CONFIRM UBER"
        case .cancel: return "CANCEL RIDE"
        case .getDirections: return "GET DIRECTIONS"
        case .pickup: return "PICKUP PASSENGER"
        case .dropOff: return "DROP OFF PASSENGER"
        }
    }
    
    init() {
        self = .requestRide
    }
}

private let kDebugRideActionView = "DEBUG RideActionView"
class RideActionView: UIView {
    
    // MARK: - Properties
    
    var destination: MKPlacemark? {
        didSet {
            titleLabel.text = destination?.name
            addressLabel.text = destination?.address
        }
    }
    
    var config = RideActionViewConfiguration()
    var buttonAction = ButtonAction()
    weak var delegate: RideActionViewDelegate?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
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
        delegate?.uploadTrip(self)
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
    
    public func configureUI(with config: RideActionViewConfiguration) {
        switch config {
        case .requestRide: break
        case .tripAccepted:
            titleLabel.text = "En Route To Passenger"
            buttonAction = .getDirections
            actionButton.setTitle(buttonAction.description, for: .normal)
        case .pickupPassenger: break
        case .tripInProgress: break
        case .endTrip: break
        }
    }
}
