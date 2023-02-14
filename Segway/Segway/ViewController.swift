//
//  ViewController.swift
//  Segway
//
//  Created by Fery Lancz on 10/04/15.
//  Copyright (c) 2015 Fery Lancz. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    @IBOutlet weak var leftSlider: UISlider!
    @IBOutlet weak var rightSlider: UISlider!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var angleLabel: UILabel!
    @IBOutlet weak var pwmLabel: UILabel!
    
    let segway = Segway()
    let motionManager = CMMotionManager()
    let data: CMAttitudeReferenceFrame!
    let rollScale = (lowerMaxRange: -20.0, upperMaxRange: 20.0, factor: 5.0, lowerMinRange: -5.0, upperMinRange: 5.0)
    let pitchScale = (lowerMaxRange: -20.0, upperMaxRange: 20.0, factor: 5.0, lowerMinRange: -5.0, upperMinRange: 5.0)
    var rawValue = (roll: 0.0, pitch: 0.0)
    var offset = (roll: 37.0, pitch: 0.0)
    var scaled = (roll: 0.0, pitch: 0.0)
    var factor = (proportional: 2.0, derivative: 1.2, pwmScale: 1.0)
    var steeringBySensors = (speed: false, steering: false);
    
    @IBAction func calibratePressed(sender: AnyObject) {
        calibrate();
    }
    
    @IBAction func leftSliderEditingDidEnd(sender: AnyObject) {
        if !steeringBySensors.speed {
            leftSlider.setValue(0, animated: true)
        }
    }
    @IBAction func rightSliderEditingDidEnd(sender: AnyObject) {
        if !steeringBySensors.steering {
            rightSlider.setValue(0, animated: true)
        }
    }
    
    func updateData() {
        statusLabel.text = segway.connectionStatus.rawValue
        segway.setSpeed(leftSlider.value, steer: rightSlider.value)
        angleLabel.text = NSString(format: "%.2f", segway.angle) + "°"
        pwmLabel.text = String(segway.pwm) + "%"
    }
    
    func calibrate() {
        if steeringBySensors.speed {
            offset.roll = rawValue.roll
        }
        if steeringBySensors.steering {
            offset.pitch = rawValue.pitch
        }
    }
    
    func setSliders(left: Double, right: Double) {
        leftSlider.setValue(Float(left), animated: true)
        rightSlider.setValue(Float(right), animated: true)
    }
    
    func scale() {
        scaled.roll = rawValue.roll
        scaled.roll -= offset.roll
        scaled.roll = scaled.roll < rollScale.lowerMaxRange ? rollScale.lowerMaxRange : scaled.roll
        scaled.roll = scaled.roll > rollScale.upperMaxRange ? rollScale.upperMaxRange : scaled.roll
        scaled.roll *= rollScale.factor
        scaled.roll = scaled.roll > rollScale.lowerMinRange && scaled.roll < rollScale.upperMinRange ? 0 : scaled.roll
        
        scaled.pitch = rawValue.pitch
        scaled.pitch -= offset.pitch
        scaled.pitch = scaled.pitch < pitchScale.lowerMaxRange ? pitchScale.lowerMaxRange : scaled.pitch
        scaled.pitch = scaled.pitch > pitchScale.upperMaxRange ? pitchScale.upperMaxRange : scaled.pitch
        scaled.pitch *= pitchScale.factor
        scaled.pitch = scaled.pitch > pitchScale.lowerMinRange && scaled.pitch < pitchScale.upperMinRange ? 0 : scaled.pitch
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toSettingsView" {
            let settingsViewController = segue.destinationViewController as SettingsViewController
            settingsViewController.steeringBySensors = steeringBySensors
            settingsViewController.proportionalValue = factor.proportional
            settingsViewController.derivativeValue = factor.derivative
            settingsViewController.pwmScale = factor.pwmScale
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if steeringBySensors.speed || steeringBySensors.steering {
            if motionManager.deviceMotionAvailable {
                motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: {deviceManager, error in
                    self.rawValue.roll = deviceManager.attitude.roll * (180 / M_PI)
                    self.rawValue.pitch = deviceManager.attitude.pitch * (180 / M_PI)
                    self.scale()
                    if self.steeringBySensors.speed {
                        self.leftSlider.setValue(Float(self.scaled.roll), animated: true)
                    }
                    if self.steeringBySensors.steering {
                        self.rightSlider.setValue(Float(self.scaled.pitch), animated: true)
                    }
                })
            }
        }
        else {
            motionManager.stopDeviceMotionUpdates()
            
        }
        leftSlider.enabled = !steeringBySensors.speed
        rightSlider.enabled = !steeringBySensors.steering
        segway.setFactors(Float(factor.proportional), derivative: Float(factor.derivative), pwmScale: Float(factor.pwmScale))
        calibrate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "leather.jpg")!)
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("updateData"), userInfo: nil, repeats: true)
        let trans = CGAffineTransformMakeRotation(CGFloat(M_PI * 1.5))
        leftSlider.transform = trans
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01
        }
        segway.connect()
    }
    
    @IBAction func close(segue: UIStoryboardSegue) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
