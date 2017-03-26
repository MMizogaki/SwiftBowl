//
//  SwipeDetectionViewController.swift
//  SuperBowl
//
//  Created by mitsuyoshi.yamazaki on 2017/03/20.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

protocol SwipeDetectionViewControllerDelegate: class {
    func swipeDetectionViewController(controller: SwipeDetectionViewController, didUpdateTouch touch: SwipeDetectionViewController.TouchPoint)
}

final class SwipeDetectionViewController: UIViewController, IBInstantiatable {

    // MARK: Public Interfaces
    struct TouchPoint {
        let location: CGPoint
        let force: CGFloat?
        let tappedAt: Date
        let velocity: CGFloat
        let circleCenterPoint: CGPoint?
        let radius: CGFloat?
        
        static func zero(location: CGPoint, tappedAt: Date) -> TouchPoint {
            return self.init(location: location, force: nil, tappedAt: tappedAt, velocity: 0.0, circleCenterPoint: nil, radius: nil)
        }
    }

    weak var delegate: SwipeDetectionViewControllerDelegate?
    
    /// スワイプ経路の3点から円の中心を算出するが、その3点を選択する際にどれだけ過去にさかのぼるかを決定するパラメータ
    /// 小さくすると直近のノイズに弱くなり、大きくすると安定するが過去のノイズに弱くなる
    var circleCalculationInterval = 30 {
        didSet {
            if self.circleCalculationInterval <= 0 {
                fatalError("1以上")
            }
        }
    }
    
    // MARK: -
    @IBOutlet private weak var detectionView: SwipeDetectionView! {
        didSet {
            self.detectionView.delegate = self
        }
    }
    @IBOutlet private weak var circleView: UIView! {
        didSet {
            self.circleView.layer.borderColor = UIColor.white.cgColor
            self.circleView.layer.borderWidth = 1.0
            self.circleView.isHidden = true
        }
    }
    
    private var touchPoints: [TouchPoint] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    // MARK: -
    private func calculateCircleCenter(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint? {
        
        let m0 = p2.y * p1.x
            - p1.y * p2.x
            + p3.y * p2.x
            - p2.y * p3.x
            + p1.y * p3.x
            - p3.y * p1.x
        
        let x = ((pow(p1.x, 2) + pow(p1.y, 2)) * (p2.y - p3.y)
            + (pow(p2.x, 2) + pow(p2.y, 2)) * (p3.y - p1.y)
            + (pow(p3.x, 2) + pow(p3.y, 2)) * (p1.y - p2.y))
            / (m0 * 2.0)
        
        let y = 0
            - ((pow(p1.x, 2) + pow(p1.y, 2)) * (p2.x - p3.x)
                + (pow(p2.x, 2) + pow(p2.y, 2)) * (p3.x - p1.x)
                + (pow(p3.x, 2) + pow(p3.y, 2)) * (p1.x - p2.x))
            / (m0 * 2.0)
        
        guard x.isNaN == false,
            y.isNaN == false,
            x.isInfinite == false,
            y.isInfinite == false
            else {
                return nil
        }
        return CGPoint(x: x, y: y)
    }
    
    private func convertTouchParameters(touch: UITouch) -> TouchPoint {
        // TODO: 古いtouchPointを削除する処理を入れたい
        
        let point = touch.location(in: detectionView)
        let now = Date()
        let p3: TouchPoint
        let force: CGFloat?
        
        if self.traitCollection.forceTouchCapability == .available {
            force = touch.force
        } else {
            force = nil
        }
        
        let p2Index = self.touchPoints.count - self.circleCalculationInterval
        let p1Index = self.touchPoints.count - (self.circleCalculationInterval * 2)
        
        if p2Index >= 0 {
            
            let p2 = self.touchPoints[p2Index]
            let interval = now.timeIntervalSince(p2.tappedAt)
            let distance = (point - p2.location).length
            let velocity = distance / CGFloat(interval)
            var centerPoint: CGPoint? = nil
            var radius: CGFloat? = nil
            
            if p1Index >= 0 {
                let p1 = self.touchPoints[p1Index]
                
                if let c = self.calculateCircleCenter(p1: p1.location, p2: p2.location, p3: point) {
                    
                    radius = sqrt(pow(c.x-p1.location.x,2)+pow(c.y-p1.location.y,2))
                    centerPoint = c
                    
                    let diameter = radius! * 2.0
                    self.circleView.isHidden = false
                    self.circleView.frame.size = CGSize(width: diameter, height: diameter)
                    self.circleView.layer.cornerRadius = radius!
                    self.circleView.center = c
                }
            }
            p3 = TouchPoint(location: point, force: force, tappedAt: now, velocity: velocity, circleCenterPoint: centerPoint, radius: radius)
            
        } else {
            p3 = TouchPoint(location: point, force: force, tappedAt: now, velocity: 0.0, circleCenterPoint: nil, radius: nil)
        }
        
        return p3
    }
    
    fileprivate func addTouch(touch: UITouch) {
        
        let touchPoint = self.convertTouchParameters(touch: touch)
        
        self.touchPoints.append(touchPoint)
        self.delegate?.swipeDetectionViewController(controller: self, didUpdateTouch: touchPoint)
    }
    
    fileprivate func touchEnded(touch: UITouch) {
        
        let touchPoint = self.convertTouchParameters(touch: touch)
        
        self.touchPoints.append(touchPoint)
        self.delegate?.swipeDetectionViewController(controller: self, didUpdateTouch: touchPoint)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            
            let zeroVelocityPoint = TouchPoint.zero(location: touchPoint.location, tappedAt: Date())
            
            self.touchPoints.append(zeroVelocityPoint)
            self.delegate?.swipeDetectionViewController(controller: self, didUpdateTouch: zeroVelocityPoint)
        }
    }
}

extension SwipeDetectionViewController: SwipeDetectionViewDelegate {
    func swipeDetectionView(detectionView: SwipeDetectionView, didUpdateTouch touch: UITouch) {
        self.addTouch(touch: touch)
    }
    
    func swipeDetectionView(detectionView: SwipeDetectionView, didEndTouch touch: UITouch) {
        self.touchEnded(touch: touch)
    }
}
