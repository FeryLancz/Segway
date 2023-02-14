//
//  SettingsViewController.swift
//  Segway
//
//  Created by Fery Lancz on 10/04/15.
//  Copyright (c) 2015 Fery Lancz. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var useSensorSpeed: UISwitch!
    @IBOutlet weak var useSensorSteering: UISwitch!
    @IBOutlet weak var proportionalLabel: UILabel!
    @IBOutlet weak var derivativeLabel: UILabel!
    @IBOutlet weak var pwmScaleLabel: UILabel!
    
    var steeringBySensors = (speed: false, steering: false);
    var animeBackground = false
    var proportionalValue = 2.0
    var derivativeValue = 1.2
    var pwmScale = 1.0
    
    @IBAction func buttonPressed(sender: AnyObject) {
        switch sender.tag {
        case 0:
            proportionalValue += 0.1
        case 1:
            proportionalValue -= 0.1
        case 2:
            derivativeValue += 0.1
        case 3:
            derivativeValue -= 0.1
        case 4:
            pwmScale += 0.1
        case 5:
            pwmScale -= 0.1
        default:
            0
        }
        proportionalLabel.text = NSString(format: "%.1f", proportionalValue)
        derivativeLabel.text = NSString(format: "%.1f", derivativeValue)
        pwmScaleLabel.text = NSString(format: "%.1f", pwmScale);
    }
    
    override func viewWillAppear(animated: Bool) {
        useSensorSpeed.setOn(steeringBySensors.speed, animated: true)
        useSensorSteering.setOn(steeringBySensors.steering, animated: true)
        proportionalLabel.text = NSString(format: "%.1f", proportionalValue)
        derivativeLabel.text = NSString(format: "%.1f", derivativeValue)
        pwmScaleLabel.text = NSString(format: "%.1f", pwmScale);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let viewController = segue.destinationViewController as ViewController
        viewController.steeringBySensors.speed = useSensorSpeed.on
        viewController.steeringBySensors.steering = useSensorSteering.on
        viewController.factor.proportional = proportionalValue
        viewController.factor.derivative = derivativeValue
        viewController.factor.pwmScale = pwmScale
    }
}
