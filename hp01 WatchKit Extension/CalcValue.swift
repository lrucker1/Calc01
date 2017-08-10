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

protocol CalcValueArithmetic {
    static func +(lhs: Self, rhs: Self) -> Self
    static func -(lhs: Self, rhs: Self) -> Self
    static func *(lhs: Self, rhs: Self) -> Self
    static func /(lhs: Self, rhs: Self) -> Self
}

class AbstractValue {
    var currentValue: String = "0"
    var valueChanged = false

    var rawValue: Any {
        get {
            return currentValue
        }
    }

    var canRepeatCommands: Bool {
        get {
            return true
        }
    }

    init() {
    }

    init(withString:String) {
        currentValue = withString
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

    func adding(_ right:AbstractValue) -> AbstractValue? { return nil }
    func subtracting(_ right:AbstractValue) -> AbstractValue? { return nil }
    func multiplying(_ right:AbstractValue) -> AbstractValue? { return nil }
    func dividing(_ right:AbstractValue) -> AbstractValue? { return nil }
    // MARK: Operators
    static func +(left: AbstractValue, right: AbstractValue) -> AbstractValue? {
        return left.adding(right)
    }

    static func -(left: AbstractValue, right: AbstractValue) -> AbstractValue? {
        return left.subtracting(right)
    }

    static func *(left: AbstractValue, right: AbstractValue) -> AbstractValue? {
        return left.multiplying(right)
    }

    static func /(left: AbstractValue, right: AbstractValue) -> AbstractValue? {
        return left.dividing(right)
    }

}

class DecimalValue : AbstractValue {

    var containsDecimalPoint = false

    override var rawValue: Any {
        get {
            return doubleValue
        }
    }

    var timeIntervalValue: TimeInterval {
        get {
            // Convert hours to seconds.
            return doubleValue * 60 * 60
        }
    }

    convenience init(withNumber number:Double) {
        self.init()
        setCurrentValue(value: number)
    }

    // TODO: This is not localized. Use Scanner
    var doubleValue: Double {
        get {
            return (currentValue as NSString).doubleValue
        }
    }

    // A decimal can turn into time or date if it is just digits.
    override var canChangeMode : Bool {
        get {
            return !containsDecimalPoint
        }
    }

    override func decimalPressed(_ str:String) -> Bool {
        if !currentValue.contains(str) {
            currentValue += str
            containsDecimalPoint = true
        }
        return true
    }

    override func plusMinusPressed() -> Bool {
        setCurrentValue(value:-doubleValue)
        valueChanged = true
        return true
    }

    override func percentPressed() -> Bool {
        let value = doubleValue / 100
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
    // MARK: Operators
    override func adding(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self + rightDV }
        if let rightTE = right as? TimeElapsedValue { return self + rightTE }
        return nil
    }
    override func subtracting(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self - rightDV }
        return nil
    }
    override func multiplying(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self * rightDV }
        return nil
    }
    override func dividing(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self / rightDV }
        return nil
    }
    static func +(left: DecimalValue, right: DecimalValue) -> AbstractValue? {
        guard let rawLeft = left.rawValue as? Double else {return nil}
        guard let rawRight = right.rawValue as? Double else {return nil}
        return DecimalValue(withNumber:rawLeft + rawRight)
    }

    static func -(left: DecimalValue, right: DecimalValue) -> AbstractValue? {
        guard let rawLeft = left.rawValue as? Double else {return nil}
        guard let rawRight = right.rawValue as? Double else {return nil}
        return DecimalValue(withNumber:rawLeft - rawRight)
    }

    static func *(left: DecimalValue, right: DecimalValue) -> AbstractValue? {
        guard let rawLeft = left.rawValue as? Double else {return nil}
        guard let rawRight = right.rawValue as? Double else {return nil}
        return DecimalValue(withNumber:rawLeft * rawRight)
    }

    static func /(left: DecimalValue, right: DecimalValue) -> AbstractValue? {
        guard let rawLeft = left.rawValue as? Double else {return nil}
        guard let rawRight = right.rawValue as? Double else {return nil}
        return DecimalValue(withNumber:rawLeft / rawRight)
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

    var dateValue: Date? {
        get {
            return Calendar.current.date(from:timeComponents())
        }
    }

    var dateComponentsValue: DateComponents {
        get {
            return timeComponents()
        }
    }

    var negativeDateComponentsValue: DateComponents? {
        get {
            let dc = timeComponents()
            let h = dc.hour ?? 0
            let m = dc.minute ?? 0
            let s = dc.second ?? 0
            return DateComponents(hour:-h, minute:-m, second:-s)
        }
    }

    convenience init(withDate date:Date) {
        // Doc says making DateFormatters is expensive and should be static.
        // We are an elapsed time, not a time of day, so no AM/PM.
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm:ss"
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
        // We only need to validate the last segment, previous ones got validated as they were entered.
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
    // MARK: Operators
    override func adding(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self + rightDV }
        if let rightTE = right as? TimeElapsedValue { return self + rightTE }
        return nil
    }
    override func subtracting(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self - rightDV }
        //if let rightTE = right as? TimeElapsedValue { return self - rightTE }
        return nil
    }
    static func +(left: TimeElapsedValue, right: DecimalValue) -> AbstractValue? {
        guard let rawLeft = left.dateValue else {return nil}
        let rawRight = right.timeIntervalValue
        return TimeElapsedValue(withDate:rawLeft + rawRight)
    }

    static func -(left: TimeElapsedValue, right: DecimalValue) -> AbstractValue? {
        guard let rawLeft = left.dateValue else {return nil}
        let rawRight = right.timeIntervalValue
        return TimeElapsedValue(withDate:rawLeft - rawRight)
    }
    static func +(left: DecimalValue, right: TimeElapsedValue) -> AbstractValue? {
        guard let rawRight = right.dateValue else {return nil}
        let rawLeft = left.timeIntervalValue
        return TimeElapsedValue(withDate:rawRight + rawLeft)
    }
/*
    static func -(left: DecimalValue, right: TimeElapsedValue) -> AbstractValue? {
        guard let rawRight = right.dateValue else {return nil}
        let rawLeft = left.timeIntervalValue
        return TimeElapsedValue(withDate:rawLeft - rawRight)
    }
*/

    static func +(left: TimeElapsedValue, right: TimeElapsedValue) -> AbstractValue? {
        let leftDC = left.dateComponentsValue
        let rightDC = right.dateComponentsValue
        guard let leftDate = Calendar.current.date(from:leftDC) else { return nil }
        guard let result = Calendar.current.date(byAdding:rightDC, to:leftDate) else {return nil}
        return TimeElapsedValue(withDate:result)
    }

    static func -(left: TimeElapsedValue, right: TimeElapsedValue) -> AbstractValue? {
        let leftDC = left.dateComponentsValue
        guard let rightDC = right.negativeDateComponentsValue else { return nil }
        guard let leftDate = Calendar.current.date(from:leftDC) else { return nil }
        guard let result = Calendar.current.date(byAdding:rightDC, to:leftDate) else {return nil}
        return TimeElapsedValue(withDate:result)
    }

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
        super.init()
        if let decimalValue = calcValue as? DecimalValue {
            decimalValue.setCurrentValue(value:number)
        }
    }

    init(withDate date:Date) {
        super.init()
        calcValue = TimeElapsedValue.init(withDate:date)
    }

    init(withValue av:AbstractValue) {
        super.init()
        calcValue = av
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

    // MARK: Operators
    static func +(left: CalcValue, right: CalcValue) -> CalcValue? {
        if let av = left.calcValue.adding(right.calcValue) {
            return CalcValue(withValue:av)
        }
        return nil
    }
    static func -(left: CalcValue, right: CalcValue) -> CalcValue? {
        if let av = left.calcValue - right.calcValue {
            return CalcValue(withValue:av)
        }
        return nil
    }
    static func *(left: CalcValue, right: CalcValue) -> CalcValue? {
        if let av = left.calcValue * right.calcValue {
            return CalcValue(withValue:av)
        }
        return nil
    }
    static func /(left: CalcValue, right: CalcValue) -> CalcValue? {
        if let av = left.calcValue / right.calcValue {
            return CalcValue(withValue:av)
        }
        return nil
    }

}
