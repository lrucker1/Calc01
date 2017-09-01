//
//  ViewController.swift
//  hp01
//
//  Created by Lee Ann Rucker on 8/8/17.
//  Copyright © 2017 Lee Ann Rucker. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // Turning this on is useful for testing, but it ignores L10N.
    // The watch sim doesn't do custom fonts or locales, so those have to be debugged here.
    // If you see a '-' on the dateSep button, you have left it on.
    let useShortForm = false

    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var operatorLabel: UILabel!
    @IBOutlet weak var amLabel: UILabel!
    @IBOutlet weak var pmLabel: UILabel!
    @IBOutlet weak var ampmButton: UIButton!
    @IBOutlet weak var decimalButton: UIButton!
    @IBOutlet weak var timeSepButton: UIButton!
    @IBOutlet weak var dateSepButton: UIButton!
    @IBOutlet weak var percentButton: UIButton!
    @IBOutlet weak var ampmGroup: UIView!
    @IBOutlet weak var clockImage: UIView!
    @IBOutlet weak var clockGroup: UIView!

    var alphanumericFont: UIFont!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Configure interface objects here.
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current
        percentButton.setTitle(NumberFormatter().percentSymbol, for:.normal)

        let configResult = configure(timeFormatter:timeFormatter, useShortForm: useShortForm)
        if configResult.is24 {
            if let img = UIImage(named:"clock") {
                ampmButton.setTitle("", for:.normal)
                ampmButton.setImage(img, for:.normal)
            }
        } else {
            amLabel.text = timeFormatter.amSymbol
            pmLabel.text = timeFormatter.pmSymbol
            ampmButton.setTitle(timeFormatter.amSymbol, for:.normal)
        }
        timeSepButton.setTitle(configResult.timeSep, for:.normal)
        if configResult.dateSep != "/" {
            // The nib has "⁄" which is less likely to look like division.
            dateSepButton.setTitle(configResult.dateSep, for:.normal)
        }
        decimalButton.setTitle(CalcValue.decimalSeparator, for:.normal)
        ampmGroup.isHidden = true
        clockGroup.isHidden = true
        let pointSize = displayLabel.font.pointSize
        alphanumericFont = UIFont(name: "DSEG14ClassicMini-BoldItali", size: pointSize)
        // Since DSEG7 looks better for numbers, it's the default with DSEG14 as a fallback.
        // But an alphanumeric string should go directly to DSEG14.
        if let font7 = UIFont(name: "DSEG7ClassicMini-BoldItalic", size: pointSize),
            alphanumericFont != nil {
            let originalDescriptor = font7.fontDescriptor;

            let fallbackDescriptor = originalDescriptor.addingAttributes([UIFontDescriptor.AttributeName.name:"DSEG14ClassicMini-BoldItali"])

            let repaired = originalDescriptor.addingAttributes([UIFontDescriptor.AttributeName.cascadeList:NSArray(object:fallbackDescriptor)])

            displayLabel.font = UIFont(descriptor:repaired, size:pointSize)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func configure(timeFormatter: DateFormatter, useShortForm:Bool = false) -> (is24:Bool, timeSep:String, dateSep:String) { return (false, "/", ":") }

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

    func setDisplayLabel(withAlphanumericString str:String) {
        if let font = alphanumericFont {
            let attrStr = NSAttributedString(string:str, attributes:[NSAttributedStringKey.font: font])
            displayLabel.attributedText = attrStr
        } else {
            displayLabel.text = str
        }
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

