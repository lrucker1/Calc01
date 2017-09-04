//
//  InterfaceController.swift
//  RetroCalc WatchKit Extension
//
//  Created by Lee Ann Rucker on 8/8/17.
//  Copyright © 2017 Lee Ann Rucker. All rights reserved.
//
// TODO: Automatic constant: save the command and the right-value: xx?yy=, zz= becomes zz?yy=

import WatchKit
import Foundation

public struct WatchState {

     public static var screenWidth: CGFloat {
          return WKInterfaceDevice.current().screenBounds.width
     }

     public static var is38: Bool {
          return screenWidth == 136
     }

     public static var is42: Bool {
          return screenWidth == 156
     }
}

class InterfaceController: WKInterfaceController {
    @IBOutlet weak var displayLabel: WKInterfaceLabel!
    @IBOutlet weak var operatorLabel: WKInterfaceLabel!
    @IBOutlet weak var ampmGroup: WKInterfaceGroup!
    @IBOutlet weak var clockImage: WKInterfaceImage!
    @IBOutlet weak var clockGroup: WKInterfaceGroup!
    @IBOutlet weak var amLabel: WKInterfaceLabel!
    @IBOutlet weak var pmLabel: WKInterfaceLabel!
    @IBOutlet weak var ampmButton: WKInterfaceButton!
    @IBOutlet weak var decimalButton: WKInterfaceButton!
    @IBOutlet weak var percentButton: WKInterfaceButton!
    @IBOutlet weak var timeSepButton: WKInterfaceButton!
    @IBOutlet weak var dateSepButton: WKInterfaceButton!

    var alphanumericFont: UIFont!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        // Watch uses short form (7-seg font) which forces the format to HP-01 standard.
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current
        percentButton.setTitle(NumberFormatter().percentSymbol)

        let configResult = configure(timeFormatter:timeFormatter, useShortForm:true)
        if !configResult.is24 {
            amLabel.setText(timeFormatter.amSymbol)
            pmLabel.setText(timeFormatter.pmSymbol)
        }
        ampmGroup.setHidden(true)
        clockGroup.setHidden(true)
        // DSEG7 is the primary font. We might get a H or BE for non-Gregorian calendars; they're OK, if funny looking.
        // The DSEG14 numbers are too cluttered at watchface sizes.
        // The watch doesn't set fallback fonts; instead, we do our best to not cause it to need to mix fonts.
        // This means it limits numeric punctuation to 7-seg's '-', ':' and '.'
        // Watch does not show DayOfWeek. If it did, use DSEG14.
        alphanumericFont = UIFont.systemFont(ofSize: CGFloat(WatchState.is38 ? 15.0 : 16.0))
        //alphanumericFont = UIFont(name: "DSEG14ClassicMini-BoldItali", size: CGFloat(WatchState.is38 ? 15.0 : 16.0))
    }

    func configure(timeFormatter: DateFormatter, useShortForm:Bool = false) -> (is24:Bool, timeSep:String, dateSep:String) { return (false, "-", ":") }

    func updateDisplay() {
    }

    func showingCurrentTime(_ ct:Bool) {
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        updateDisplay()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    // Slow single blink for successful entry, fast double blink for error.
    func blinkDisplay(_ on:Bool) {
        let color = on ? UIColor.red : UIColor.black
        displayLabel.setTextColor(color)
        operatorLabel.setTextColor(color)
        amLabel.setTextColor(color)
        pmLabel.setTextColor(color)
        clockImage.setHidden(!on)
    }

    func setOperatorLabel(_ str:String) {
        operatorLabel.setText(str)
    }

    func setDisplayLabel(withAlphanumericString str:String) {
        // DSEG7 has letters, but they're ugly.
        if let font = alphanumericFont {
            // rdar://34192205 - there are two sets of these consts, one is font and one fontAttributeName. Make it shut up by hardcoding.
            // Yes, this is sooo very bad form, which is why it's DEBUG only. "Generic iOS Device" wants "font" so that's what release builds get.
#if DEBUG
            let attrStr = NSAttributedString(string:str, attributes:[NSAttributedStringKey("NSFont"): font])
#else
            let attrStr = NSAttributedString(string:str, attributes:[NSAttributedStringKey.font: font])
#endif
           displayLabel.setAttributedText(attrStr)
        } else {
            displayLabel.setText(str)
        }
    }

    func setDisplayLabel(_ str:String) {
        displayLabel.setText(str)
    }

    func setAMPMState(isTimeOfDay: Bool, isPM: Bool = false, uses24HourTime: Bool = false) {
         if isTimeOfDay {
            // The number field is always shifted over for TOD values.
            // The HP calculator changed the format to "h:mm ss". We have ampm group & icons.
            if uses24HourTime {
                clockGroup.setHidden(false)
            } else {
                ampmGroup.setHidden(false)
                amLabel.setHidden(isPM || uses24HourTime)
                pmLabel.setHidden(!isPM || uses24HourTime)
            }
        } else {
            ampmGroup.setHidden(true)
            clockGroup.setHidden(true)
        }
	}
}
