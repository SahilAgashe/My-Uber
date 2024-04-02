//
//  CircularProgressView.swift
//  MyUber
//
//  Created by SAHIL AMRUT AGASHE on 02/04/24.
//

import UIKit

class CircularProgressView: UIView {
    
    // MARK: - Properties
    
    var progressLayer: CAShapeLayer!
    var trackLayer: CAShapeLayer!
    var pulsatingLayer: CAShapeLayer!

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCircleLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureCircleLayers()
    }
    
    // MARK: - Helpers
    
    private func configureCircleLayers() {
        pulsatingLayer = circleShapeLayer(strokeColor: .clear, fillColor: .blue)
        layer.addSublayer(pulsatingLayer)
        
        trackLayer = circleShapeLayer(strokeColor: .clear, fillColor: .clear)
        layer.addSublayer(trackLayer)
        trackLayer.strokeEnd = 1
        
        progressLayer = circleShapeLayer(strokeColor: .systemPink, fillColor: .clear)
        layer.addSublayer(progressLayer)
        trackLayer.strokeEnd = 1
    }
    
    private func circleShapeLayer(strokeColor: UIColor, fillColor: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        
        let center = CGPoint(x: 0, y: 32)
        let circularPath = UIBezierPath(arcCenter: center,
                                        radius: frame.width / 2.5,
                                        startAngle: -(.pi / 2), endAngle: 1.5 * .pi,
                                        clockwise: true)
        
        layer.path = circularPath.cgPath
        layer.strokeColor = strokeColor.cgColor
        layer.lineWidth = 12
        layer.fillColor = fillColor.cgColor
        layer.lineCap = .round
        layer.position = self.center
        
        return layer
    }
}

