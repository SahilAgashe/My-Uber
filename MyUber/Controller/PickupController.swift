//
//  PickupController.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 26/02/24.
//

import UIKit
import MapKit
import FirebaseDatabase

protocol PickupControllerDelegate: AnyObject {
    func didAcceptTrip(_ trip: Trip)
}

private let kDebugPickupController = "DEBUG PickupController"
class PickupController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: PickupControllerDelegate?
    private let mapView = MKMapView()
    let trip: Trip
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "baseline_clear_white_36pt_2x")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleDismissal), for: .touchUpInside)
        return button
    }()
    
    private let pickupLabel: UILabel = {
        let label = UILabel()
        label.text = "Would you like to pickup this passenger?"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    private lazy var acceptTripButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleAcceptTrip), for: .touchUpInside)
        button.backgroundColor = .white
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        button.setTitleColor(.black, for: .normal)
        button.setTitle("ACCEPT TRIP", for: .normal)
        return button
    }()
    
    // MARK: - Init
    
    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureMapView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(kDebugPickupController, #function)
    }
    
    // MARK: - Selectors
    
    @objc private func handleAcceptTrip() {
        DriverService.shared.acceptTrip(trip: trip) { [weak self ] (error: Error?, ref: DatabaseReference) in
            guard let self else { return }
            self.delegate?.didAcceptTrip(self.trip)
        }
    }
    
    @objc private func handleDismissal() {
        dismiss(animated: true)
    }
    
    // MARK: - API
    
    // MARK: - Helpers
    
    private func configureMapView() {
        let region = MKCoordinateRegion(center: trip.pickupCoordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: false)
        
        mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
    }
    
    private func configureUI() {
        view.backgroundColor = .backgroundColor
        
        view.addSubview(cancelButton)
        cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,
                            paddingTop: 10, paddingLeft: 16)
        
        view.addSubview(mapView)
        mapView.setDimensions(height: 270, width: 270)
        mapView.layer.cornerRadius = 270 / 2
        mapView.centerX(inView: view)
        mapView.centerY(inView: view, constant: -200)
        
        view.addSubview(pickupLabel)
        pickupLabel.centerX(inView: view)
        pickupLabel.anchor(top: mapView.bottomAnchor, paddingTop: 16)
        
        view.addSubview(acceptTripButton)
        acceptTripButton.anchor(top: pickupLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 16, paddingLeft: 32, paddingRight: 32, height: 50)
    }
}
