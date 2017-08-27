//
//  ViewController.swift
//  hp01
//
//  Created by Lee Ann Rucker on 8/8/17.
//  Copyright © 2017 Lee Ann Rucker. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var operatorLabel: UILabel!
    @IBOutlet weak var amLabel: UILabel!
    @IBOutlet weak var pmLabel: UILabel!
    @IBOutlet weak var decimalButton: UIButton!
    @IBOutlet weak var timeSepButton: UIButton!
    @IBOutlet weak var dateSepButton: UIButton!
    @IBOutlet weak var percentButton: UIButton!
    @IBOutlet weak var ampmGroup: UIView!
    @IBOutlet weak var clockImage: UIView!
    @IBOutlet weak var clockGroup: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Configure interface objects here.
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current
        decimalButton.setTitle(timeFormatter.locale.decimalSeparator, for:.normal)
        percentButton.setTitle(NumberFormatter().percentSymbol, for:.normal)

        let configResult = configure(timeFormatter:timeFormatter)
        if !configResult.is24 {
            amLabel.text = timeFormatter.amSymbol
            pmLabel.text = timeFormatter.pmSymbol
        }
        timeSepButton.setTitle(configResult.timeSep, for:.normal)
        dateSepButton.setTitle(configResult.dateSep, for:.normal)
        ampmGroup.isHidden = true
        clockGroup.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func configure(timeFormatter: DateFormatter) -> (is24:Bool, timeSep:String, dateSep:String) { return (false, "/", ":") }

    // Slow single blink for successful entry, fast double blink for error.
    func blinkDisplay(_ on:Bool) {
        let color = on ? UIColor.red : UIColor.black
        displayLabel.textColor = color
        operatorLabel.textColor = color
        amLabel.textColor = color
        pmLabel.textColor = color
        clockImage.isHidden = !on
    }

    func setOperatorLabel(_ str:String) {
        operatorLabel.text = str
    }
    func setDisplayLabel(_ str:String) {
        displayLabel.text = str
    }

    func setAMPMState(isTimeOfDay: Bool, isPM: Bool = false, uses24HourTime: Bool = false) {
         if isTimeOfDay {
            // The number field is always shifted over for TOD values.
            // The HP calculator changed the format to "h:mm ss". That's not even possible.
            if uses24HourTime {
                clockGroup.isHidden = false
            } else {
                ampmGroup.isHidden = false
                amLabel.isHidden = isPM || uses24HourTime
                pmLabel.isHidden = !isPM || uses24HourTime
            }
        } else {
            ampmGroup.isHidden = true
            clockGroup.isHidden = true
        }
    }
}

