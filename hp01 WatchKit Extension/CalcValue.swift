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

class AbstractValue {
    var currentValue: String = "0"
    var containsValue = false
    var isTimeOfDay = false
    var isPM = false

    var canRepeatCommands: Bool {
        get {
            return false
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
        containsValue = true
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

    func slashPressed() -> Bool {
        return false
    }

    func percentPressed() -> Bool {
        return false
    }

    func plusMinusPressed() -> Bool {
        return false
    }

    func amPMPressed() -> Bool {
        return false
    }

    func dayOfWeekPressed() -> String? {
        return nil
    }

    // Decimal can change to Time or Date when the appropriate separator is pressed.
    // Once there, they don't change back.
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

    var allowsSlash : Bool {
        get {
            return false
        }
    }

    func canonicalizeDisplayString() {
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

    override var canRepeatCommands: Bool {
        get {
            return true
        }
    }

    var timeIntervalValue: TimeInterval {
        get {
            // Convert hours to seconds.
            return doubleValue * 60 * 60
        }
    }

    var intValue: Int? {
        let value = doubleValue
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            // our value is an integer
            return Int(value)
        } else {
            // our value is a float
            return nil
        }
    }

    convenience init(withNumber number:Double) {
        self.init()
        setCurrentValue(value: number)
        containsValue = true
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
        containsValue = true
        return true
    }

    override func percentPressed() -> Bool {
        let value = doubleValue / 100
        setCurrentValue(value: value)
        containsValue = true
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
        if let rightTE = right as? TimeValue { return self + rightTE }
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
        return DecimalValue(withNumber:left.doubleValue + right.doubleValue)
    }

    static func -(left: DecimalValue, right: DecimalValue) -> AbstractValue? {
        return DecimalValue(withNumber:left.doubleValue - right.doubleValue)
    }

    static func *(left: DecimalValue, right: DecimalValue) -> AbstractValue? {
        return DecimalValue(withNumber:left.doubleValue * right.doubleValue)
    }

    static func /(left: DecimalValue, right: DecimalValue) -> AbstractValue? {
        return DecimalValue(withNumber:left.doubleValue / right.doubleValue)
    }

}

class TimeDateValue : AbstractValue {

    // Append a digit to a segment with a max length. Push extras off the front.
    func appendDigit(_ str : String, digit : String, max: Int = 2) -> String {
        var s = str + digit
        if s.count > max {
            let end = s.index(s.endIndex, offsetBy:-max)
            s = s.substring(from:end)
        }
        return s
    }

    func validateLastSegment() -> Bool {
        return true
    }

    func appendSeparator(sep:String, strings stringsIn:[String], padZeros:Bool = false) -> Bool {
        var strings = stringsIn
        if currentValue.contains(sep) {
            // If we have two separators already, or the segment is out of range, it's an error.
            if strings.count == 3 || !validateLastSegment() {
                return false
            }
            if (padZeros) {
                // This should not be possible.
                guard var lastString = strings.popLast() else { return false }
                // Add a zero segment if there isn't one.
                // Add leading zeros to one-digit segments.
                if lastString.count == 0 {
                    currentValue += "00"
                } else if lastString.count == 1 {
                    lastString = "0" + lastString
                    strings.append(lastString)
                    currentValue = strings.joined(separator:sep)
                }
            }
        } else {
            if currentValue.count == 0 {
                currentValue = "0"
            }
        }
        currentValue += sep
        return true
    }
}

class DateValue : TimeDateValue {

    // TODO: Localize.
    let dateSep = "/"
    override var allowsSlash : Bool {
        get {
            return true
        }
    }

    var dateValue : Date? {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            return dateFormatter.date(from: currentValue)
        }
    }

    convenience init(withDate date:Date) {
        // Doc says making DateFormatters is expensive and should be static.
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        self.init(withString:dateFormatter.string(from:date))
        containsValue = true
    }

    override func validate() -> Bool {
        // If it makes a date, it's good.
        return dateValue != nil
    }

    // All we can do is make sure it's not zero
    override func validateLastSegment() -> Bool {
        let strings = dateSubstrings()
        guard let seg = strings.last else { return false }
        return (seg as NSString).integerValue != 0
    }

    override func dayOfWeekPressed() -> String? {
        guard let dv = dateValue else { return nil }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from:dv)
        let index = ((weekday - 1) + (calendar.firstWeekday - 1)) % 7
        return calendar.weekdaySymbols[index].uppercased()
    }

    func dateSubstrings() -> [String] {
        return currentValue.components(separatedBy: CharacterSet.init(charactersIn:dateSep))
    }

	override func slashPressed() -> Bool {
        return appendSeparator(sep: dateSep, strings: dateSubstrings())
    }

    override func appendNumber(_ newValue:String) {
        // We are entering days/months. Max lengths are 2-2-4.
        // It's far more likely that 5 is a mistake to be pushed off than a real year.
        // Unless it's yyyy-mm-dd mode. In which case, grr.
        let strings = dateSubstrings()
        if strings.count == 1 {
            currentValue = appendDigit(strings[0], digit:newValue)
        } else if strings.count == 2 {
            let s1 = strings[0]
            let s2 = appendDigit(strings[1], digit:newValue)
            currentValue = [s1, s2].joined(separator:dateSep)
        } else {
            let s1 = strings[0]
            let s2 = strings[0]
            let s3 = appendDigit(strings[1], digit:newValue, max:4)
            currentValue = [s1, s2, s3].joined(separator:dateSep)
        }
	}

    // MARK: Operators
    // Allowed: Date +/ decimal(days) = Date, Date - Date = decimal(days)
    override func adding(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self + rightDV }
        return nil
    }
    override func subtracting(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self - rightDV }
        if let rightDT = right as? DateValue { return self - rightDT }
        return nil
    }

    static func +(left: DateValue, right: DecimalValue) -> AbstractValue? {
        guard let rawLeft = left.dateValue else {return nil}
        guard let rawRight = right.intValue else {return nil}
        let days = DateComponents(day:Int(rawRight))
        guard let newDate = Calendar.current.date(byAdding:days, to:rawLeft) else {return nil}
        return DateValue(withDate:newDate)
    }

    static func -(left: DateValue, right: DecimalValue) -> AbstractValue? {
        guard let rawLeft = left.dateValue else {return nil}
        guard let rawRight = right.intValue else {return nil}
        let days = DateComponents(day:Int(-rawRight))
        guard let newDate = Calendar.current.date(byAdding:days, to:rawLeft) else {return nil}
        return DateValue(withDate:newDate)
    }

    static func -(left: DateValue, right: DateValue) -> AbstractValue? {
        // Duration is end - start
        guard let end = left.dateValue else {return nil}
        guard let start = right.dateValue else {return nil}
        if end < start {return nil}
        let di = DateInterval(start:start, end:end)
        let ti = di.duration // TimeInterval: in seconds
        return DecimalValue(withNumber:ti / (60 * 60 * 24))
    }
}

class TimeValue : TimeDateValue {

    override var allowsColons : Bool {
        get {
            return true
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

    init(withDate date:Date) {
        // Doc says making DateFormatters is expensive and should be static.
        // If we're a time of day it shows up as a label, so no AM/PM symbol is needed.
        let timeFormatter = DateFormatter()
        timeFormatter.setLocalizedDateFormatFromTemplate("J:mm ss")
        super.init(withString:timeFormatter.string(from:date))
        containsValue = true
        isTimeOfDay = true
    }

    init(withDecimalValue value:DecimalValue, isTimeOfDay tod: Bool = false) {
        super.init(withString:value.currentValue)
        isTimeOfDay = tod
        if isTimeOfDay {
            if let v = value.intValue {
                isPM = v > 12
            }
        }
    }

    func timeSubstrings() -> [String] {
        return currentValue.components(separatedBy: CharacterSet.init(charactersIn:": "))
    }

    func timeComponents() -> DateComponents {
        let strings = timeSubstrings()
        var dc = DateComponents()
        if (strings.count > 0) {
            var h = (strings[0] as NSString).integerValue
            if isTimeOfDay {
                if isPM && h < 12 {
                    h += 12
                }
            }
            dc.hour = h
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
        // We only need to validate the last segment, previous ones got validated as they were entered.
        return validateLastSegment()
    }

	override func validateLastSegment() -> Bool {
        let strings = timeSubstrings()
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
            // This shouldn't get reached since it's not a Time until it has a separator,
            // so we don't have to worry about elapsed vs time of day limits.
            currentValue += newValue
        }
     }

	override func colonPressed() -> Bool {
        return appendSeparator(sep: ":", strings: timeSubstrings(), padZeros:true)
    }

    override func amPMPressed() -> Bool {
        isPM = !isPM
        return true
    }

    func makeTimeOfDay() -> Bool {
        if isTimeOfDay { return false }
        isTimeOfDay = true
        let strings = timeSubstrings()
        if strings.count > 0 {
            isPM = (strings[0] as NSString).integerValue > 12
        }
        return true
    }

    // TODO: Elapsed should allow any hour value without rollover.
	override func canonicalizeDisplayString() {
        let strings = timeSubstrings()
        if strings.count < 2 {
            return
        }
        if let dv = dateValue {
            let timeFormatter = DateFormatter()
            timeFormatter.setLocalizedDateFormatFromTemplate("J:mm:ss")
            currentValue = timeFormatter.string(from:dv)
        }
    }

    // TODO: decimalPressed for hundreths.
    // MARK: Operators
    override func adding(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self + rightDV }
        if let rightTE = right as? TimeValue { return self + rightTE }
        return nil
    }
    override func subtracting(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self - rightDV }
        //if let rightTE = right as? TimeElapsedValue { return self - rightTE }
        return nil
    }
    static func +(left: TimeValue, right: DecimalValue) -> AbstractValue? {
        guard let rawLeft = left.dateValue else {return nil}
        let rawRight = right.timeIntervalValue
        return TimeValue(withDate:rawLeft + rawRight)
    }

    static func -(left: TimeValue, right: DecimalValue) -> AbstractValue? {
        guard let rawLeft = left.dateValue else {return nil}
        let rawRight = right.timeIntervalValue
        return TimeValue(withDate:rawLeft - rawRight)
    }
    static func +(left: DecimalValue, right: TimeValue) -> AbstractValue? {
        guard let rawRight = right.dateValue else {return nil}
        let rawLeft = left.timeIntervalValue
        return TimeValue(withDate:rawRight + rawLeft)
    }
/*
    static func -(left: DecimalValue, right: TimeElapsedValue) -> AbstractValue? {
        guard let rawRight = right.dateValue else {return nil}
        let rawLeft = left.timeIntervalValue
        return TimeElapsedValue(withDate:rawLeft - rawRight)
    }
*/

    static func +(left: TimeValue, right: TimeValue) -> AbstractValue? {
        let leftDC = left.dateComponentsValue
        let rightDC = right.dateComponentsValue
        guard let leftDate = Calendar.current.date(from:leftDC) else { return nil }
        guard let result = Calendar.current.date(byAdding:rightDC, to:leftDate) else {return nil}
        return TimeValue(withDate:result)
    }

    static func -(left: TimeValue, right: TimeValue) -> AbstractValue? {
        let leftDC = left.dateComponentsValue
        guard let rightDC = right.negativeDateComponentsValue else { return nil }
        guard let leftDate = Calendar.current.date(from:leftDC) else { return nil }
        guard let result = Calendar.current.date(byAdding:rightDC, to:leftDate) else {return nil}
        return TimeValue(withDate:result)
    }

}


class CalcValue: NSObject {
    var calcValue: AbstractValue = DecimalValue()
    var stringValue: String {
        get {
            return calcValue.currentValue
        }
    }

    // Does it contain a value that can be executed?
    var containsValue: Bool {
        get {
            return calcValue.containsValue
        }
    }

    // TimeOfDay values may want the AM/PM showing.
    var isTimeOfDay: Bool {
        get {
            return calcValue.isTimeOfDay
        }
    }

    var isPM: Bool {
        get {
            return calcValue.isPM
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

    init(withTime date:Date) {
        super.init()
        calcValue = TimeValue.init(withDate:date)
    }

    init(withDate date:Date) {
        super.init()
        calcValue = DateValue.init(withDate:date)
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

    func dayOfWeekPressed() -> String? {
        return calcValue.dayOfWeekPressed()
    }

    func amPMPressed() -> Bool {
        return calcValue.amPMPressed()
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
        if let dv = calcValue as? DecimalValue {
            calcValue = TimeValue(withDecimalValue:dv)
            calcValue.containsValue = true
        }
        return calcValue.colonPressed()
    }

    // Typing Time changes the mode to time, if it's an integer.
    // If it's already time, convert to TimeOfDay
    func timePressed() -> Bool {
        if !calcValue.allowsColons && !calcValue.canChangeMode {
            return false
        }
        if let dv = calcValue as? DecimalValue {
            calcValue = TimeValue(withDecimalValue:dv, isTimeOfDay:true)
            calcValue.containsValue = true
            // Add a colon now.
            return calcValue.colonPressed()
        } else if let tv = calcValue as? TimeValue {
            return tv.makeTimeOfDay()
        }
        return false
    }

    // Typing slash changes the mode to date, if it's an integer.
    func slashPressed() -> Bool {
        if !calcValue.allowsSlash && !calcValue.canChangeMode {
            return false
        }
        // We need a date value.
        if !calcValue.allowsSlash {
            calcValue = DateValue(withString:calcValue.currentValue)
            calcValue.containsValue = true
        }
        return calcValue.slashPressed()
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
