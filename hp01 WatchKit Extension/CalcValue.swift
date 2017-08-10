//
//  CalcValue.swift
//  hp01 WatchKit Extension
//
//  Created by Lee Ann Rucker on 8/10/17.
//  Copyright © 2017 Lee Ann Rucker. All rights reserved.
//

import UIKit

enum CalcValueType
{
    case Decimal
    case TimeElapsed
}

class AbstractValue : NSObject {
    var currentValue: String = "0"
    var valueChanged = false

    var rawValue: Any {
        get {
            return (currentValue as NSString).doubleValue
        }
    }

    var canRepeatCommands: Bool {
        get {
            return true
        }
    }

    override init() {
        super.init()
    }

    init(withString:String) {
        currentValue = withString
        super.init()
    }

    func validate() -> Bool {
        return true
    }

    func validateCommand(_ type:CommandType) -> Bool {
        return true
    }

    func numberPressed(_ value: Int) {
        let newValue = "\(value)"
        if currentValue == "0" {
            currentValue = newValue
        } else {
            appendNumber(newValue)
        }
        valueChanged = true
    }

    func appendNumber(_ newValue:String) {
        currentValue += newValue
    }

    func decimalPressed(_ str:String) -> Bool {
        return false
    }

    func colonPressed() -> Bool {
        return false
    }

    func percentPressed() -> Bool {
        return false
    }

    func plusMinusPressed() -> Bool {
        return false
    }
    
    var canChangeMode : Bool {
        get {
            return false
        }
    }

    var allowsColons : Bool {
        get {
            return false
        }
    }

    func canonicalizeDisplayString() {
    }

    // Not needed by Decimal. Move if all the date/times get a different common super.
    func appendDigit(_ str : String, digit : String) -> String {
        var s = str + digit
        if s.count > 2 {
            let end = s.index(s.endIndex, offsetBy:-2)
            s = s.substring(from:end)
        }
        return s
    }

}

class DecimalValue : AbstractValue {

    var containsDecimal = false

    // TODO: This is not localized. Use Scanner
    var currentDoubleValue: Double {
        get {
            return (currentValue as NSString).doubleValue
        }
    }

    // A decimal can turn into time or date if it is just numbers.
    override var canChangeMode : Bool {
        get {
            return !containsDecimal
        }
    }

    override func decimalPressed(_ str:String) -> Bool {
        if !currentValue.contains(str) {
            currentValue += str
        }
        return true
    }

    override func plusMinusPressed() -> Bool {
        setCurrentValue(value:-currentDoubleValue)
        valueChanged = true
        return true
    }

    override func percentPressed() -> Bool {
        let value = currentDoubleValue / 100
        setCurrentValue(value: value)
        valueChanged = true
        return true
    }

    func setCurrentValue(value: Double) {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            // our value is an integer
            currentValue = "\(Int(value))"
        } else {
            // our value is a float
            currentValue = "\(value)"
        }
    }

}

class TimeElapsedValue : AbstractValue {

    override var allowsColons : Bool {
        get {
            return true
        }
    }

    override var canRepeatCommands: Bool {
        get {
            return false
        }
    }

    override var rawValue: Any {
        get {
            return timeComponents() as Any
        }
    }

    convenience init(withDate date:Date) {
        // Doc says making DateFormatters is expensive.
/*
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let h = components.hour ?? 0
        let m = components.minute ?? 0
        let s = components.second ?? 0
*/
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm:ss"
        self.init(withString:timeFormatter.string(from:date))
    }

    func timeSubstrings() -> [String] {
        return currentValue.components(separatedBy: CharacterSet.init(charactersIn:":"))
    }

    func timeComponents() -> DateComponents {
        let strings = timeSubstrings()
        var dc = DateComponents()
        if (strings.count > 0) {
            dc.hour = (strings[0] as NSString).integerValue
        }
        if (strings.count > 1) {
            dc.minute = (strings[1] as NSString).integerValue
        }
        if (strings.count > 2) {
            dc.second = (strings[2] as NSString).integerValue
        }
        return dc
    }

    override func validate() -> Bool {
        let strings = timeSubstrings()
        // We only need to validate the last segment.
        switch strings.count {
            case 2:
                let m = strings[1]
                return (m as NSString).integerValue < 60

            case 3:
                let sec = strings[2]
                return (sec as NSString).integerValue < 60

            default:
                return true
        }
    }

    override func validateCommand(_ type:CommandType) -> Bool {
        return type != .Multiply && type != .Divide
    }

    override func appendNumber(_ newValue:String) {
        // We are entering minutes/seconds. There can be only two.
        let strings = timeSubstrings()
        if strings.count == 3 {
            let h = strings[0]
            let m = strings[1]
            let s = appendDigit(strings[2], digit:newValue)
            currentValue = h + ":" + m + ":" + s
        } else if strings.count == 2 {
            let h = strings[0]
            let m = appendDigit(strings[1], digit:newValue)
            currentValue = h + ":" + m
        } else {
            currentValue += newValue
        }
     }

    override func colonPressed() -> Bool {
        if currentValue.contains(":") {
            let strings = timeSubstrings()
            // If we have two colons already, or the time segment is out of range, it's an error.
            if strings.count == 3 || !validate() {
                return false
            }
            let lastString = strings.last
            // Add a zero segment if there isn't one.
            // TODO: Add leading zeros to one-digit segments.
            if lastString!.count == 0 {
                currentValue += "00"
            }
        } else {
            if currentValue.count == 0 {
                currentValue = "0"
            }
        }
        currentValue += ":"
        return true
    }

    override func canonicalizeDisplayString() {
//        if let date = Calendar.current.date(from:timeComponents()) {
//            setDisplayTime(value:date)
//        }
    }

    // TODO: decimalPressed for hundreths.
}


class CalcValue: NSObject {
    var calcValue: AbstractValue = DecimalValue()
    var stringValue: String {
        get {
            return calcValue.currentValue
        }
    }
    var valueChanged: Bool {
        get {
            return calcValue.valueChanged
        }
    }

    var rawValue: Any {
        get {
            return calcValue.rawValue
        }
    }

    var canRepeatCommands: Bool {
        get {
            return calcValue.canRepeatCommands
        }
    }

    override init() {
        super.init()
    }

    init(withNumber number:Double) {
        if let decimalValue = calcValue as? DecimalValue {
            decimalValue.setCurrentValue(value:number)
        }
        super.init()
    }

    init(withDate date:Date) {
        calcValue = TimeElapsedValue.init(withDate:date)
        super.init()
    }

    func validate() -> Bool {
        return calcValue.validate()
    }

    func validate(_ type:CommandType) -> Bool {
        return calcValue.validate() && calcValue.validateCommand(type)
    }

    func validateCommand(_ type:CommandType) -> Bool {
        return calcValue.validateCommand(type)
    }

    func numberPressed(_ value: Int) {
        calcValue.numberPressed(value)
    }

    func percentPressed() -> Bool {
        return calcValue.percentPressed()
    }

    func plusMinusPressed() -> Bool {
        return calcValue.plusMinusPressed()
    }

    // Pass in the localized decimal string.
    func decimalPressed(_ str:String) -> Bool {
        return calcValue.decimalPressed(str)
    }

    // Typing colon changes the mode to time, if it's an integer.
    func colonPressed() -> Bool {
        if !calcValue.allowsColons && !calcValue.canChangeMode {
            return false
        }
        // We need a time value.
        if !calcValue.allowsColons {
            calcValue = TimeElapsedValue(withString:calcValue.currentValue)
            calcValue.valueChanged = true
        }
        return calcValue.colonPressed()
    }

    func canonicalizeDisplayString() {
        calcValue.canonicalizeDisplayString()
    }

}
