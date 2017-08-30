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

// The HP calculator's internal math for ElapsedTime is a DecimalTimeValue
// which is time in hours for ElapsedTime and what you expect for Decimal
// For convenience, they both also support TimeInterval, which is time in seconds.
protocol DecimalTimeValue {
    var timeIntervalValue: TimeInterval {get}
    var doubleValue: Double {get}
}

// Plus/Minus should only be used when at least one is an ElapsedTimeValue;
// operating on two DecimalValues should produce a DecimalValue!
func +(left: DecimalTimeValue, right: DecimalTimeValue) -> AbstractValue? {
    let rawLeft = left.timeIntervalValue
    let rawRight = right.timeIntervalValue
    return ElapsedTimeValue(withTimeInterval:rawLeft + rawRight)
}

func -(left: DecimalTimeValue, right: DecimalTimeValue) -> AbstractValue? {
    let rawLeft = left.timeIntervalValue
    let rawRight = right.timeIntervalValue
    return ElapsedTimeValue(withTimeInterval:rawLeft - rawRight)
}

// Multiply/Divide produce a DecimalValue so it can be used with both implementations.
func *(left: DecimalTimeValue, right: DecimalTimeValue) -> AbstractValue? {
    return DecimalValue(withNumber:left.doubleValue * right.doubleValue)
}
func /(left: DecimalTimeValue, right: DecimalTimeValue) -> AbstractValue? {
    return DecimalValue(withNumber:left.doubleValue / right.doubleValue)
}

class AbstractValue {
    var currentValue: String = "0"
    var containsValue = false
    var isPM = false

    var canRepeatCommands: Bool {
        get {
            return false
        }
    }

    var isTimeOfDay: Bool {
        get {
            return false
        }
    }

    // When this is the left value, can percent be applied to the right?
    var allowsPercent: Bool {
        get {
            return false
        }
    }

    init() {
    }

    init(withString str:String) {
        currentValue = str
        containsValue = str != "0"
    }

    func validate() -> Bool {
        return true
    }

    func validateCommand(_ type:CommandType) -> Bool {
        return true
    }

    func numberPressed(_ value: Int) -> Bool {
        let newValue = "\(value)"
        containsValue = true
        if currentValue == "0" {
            currentValue = newValue
            return true
        }
        return appendNumber(newValue)
    }

    func appendNumber(_ newValue:String) -> Bool {
        currentValue += newValue
        return true
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

    func plusMinusPressed() -> Bool {
        return false
    }

    func amPMPressed() -> Bool {
        return false
    }

    func dayOfWeekPressed() -> (String, CalcValue)? {
        return nil
    }

    func applyPercent(_ pct : AbstractValue) -> AbstractValue? {
        return nil
    }

    // Decimal can change to Time or Date when the appropriate separator is pressed.
    // Once there, they don't change back.
    var canChangeMode : Bool {
        get {
            return false
        }
    }
    var canBecomeElapsedTime : Bool {
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

class DecimalValue : AbstractValue, DecimalTimeValue {

    static let numberFormatter:NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 5
        if CalcValue.useShortForm {
            formatter.decimalSeparator = "."
            formatter.exponentSymbol = "E"
        }
        return formatter
    }()

    var containsDecimalPoint = false
    var isPercent = false

    override var allowsPercent: Bool {
        get {
            return true
        }
    }

    override var canRepeatCommands: Bool {
        get {
            return true
        }
    }

    // A Decimal value is a TimeInterval for TimeOfDay or ElapsedTime, Days for Date.
    var timeIntervalValue: TimeInterval {
        get {
            // Convert hours to seconds.
            return doubleValue * 3600
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
        setCurrentValue(value:number)
        containsValue = true
    }

    var doubleValue: Double {
        get {
            if let result = DecimalValue.numberFormatter.number(from:currentValue) {
                return Double(result.doubleValue)
            }
            return 0
        }
    }

    // A decimal can turn into time or date if it is an integer.
    // Date & TOD must be 2 digits or less. TODO: handle Date vs Time, MM/DD or DD/MM...
    override var canChangeMode : Bool {
        get {
            return !containsDecimalPoint && self.doubleValue <= 31
        }
    }
	// A decimal can turn into elapsed time, even with fractions.
    // Unless the "hour" length is > 4 digits long, because then it won't fit.
    override var canBecomeElapsedTime : Bool {
        get {
            return Int(doubleValue) < CalcValue.maxHours
        }
    }
    override func appendNumber(_ newValue:String) -> Bool {
        // All decimal cares about is max length, to avoid overflowing display.
        var count = Int(currentValue.count)
        if containsDecimalPoint {
            // Decimal point doesn't count, even if it's a comma.
            // It's calculator-style with zero width.
            count -= 1
        }
        if count == CalcValue.maxDigits {
            return false
        }
        currentValue += newValue
        return true
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

    override func applyPercent(_ value : AbstractValue) -> AbstractValue? {
        guard let pctValue = value as? DecimalValue else {return nil}
        return DecimalValue(withNumber:doubleValue * pctValue.doubleValue / 100)
    }

    func setCurrentValue(value: Double) {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            // our value is an integer
            currentValue = "\(Int(value))"
            containsDecimalPoint = false
        } else if let str = DecimalValue.numberFormatter.string(from:value as NSNumber) {
            // our value is a float
            currentValue = str
            containsDecimalPoint = true
        } else {
            // Should never be reached
            currentValue = "0"
        }
    }
    // MARK: Operators
    override func adding(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self + rightDV }
        if let rightTD = right as? TimeOfDayValue { return self + rightTD }
        if let rightTE = right as? ElapsedTimeValue { return (self as DecimalTimeValue) + rightTE}
        if let rightDate = right as? DateValue { return rightDate + self }
        return nil
    }
    override func subtracting(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self - rightDV }
        if let rightTE = right as? ElapsedTimeValue { return (self as DecimalTimeValue) - rightTE }
        return nil
    }
    override func multiplying(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalTimeValue { return (self as DecimalTimeValue) * rightDV }
        if let rightTE = right as? ElapsedTimeValue { return (self as DecimalTimeValue) * rightTE}
        return nil
    }
    override func dividing(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalTimeValue { return (self as DecimalTimeValue) / rightDV }
        if let rightTE = right as? ElapsedTimeValue { return (self as DecimalTimeValue) / rightTE}
        return nil
    }
    static func +(left: DecimalValue, right: DecimalValue) -> AbstractValue? {
        return DecimalValue(withNumber:left.doubleValue + right.doubleValue)
    }

    static func -(left: DecimalValue, right: DecimalValue) -> AbstractValue? {
        return DecimalValue(withNumber:left.doubleValue - right.doubleValue)
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

    // Making DateFormatters is expensive and should be static.
    static let dateFormatter:DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        if CalcValue.useShortForm {
            formatter.dateFormat = "M'-'d'-'yy"
        }
        // Watch only has space for 4 digits with a 15-point font. If that's unreadable, flip this back.
        // formatter.setLocalizedDateFormatFromTemplate("M/d/yy")
        return formatter
    }()
    override var allowsSlash : Bool {
        get {
            return true
        }
    }

    var dateValue : Date? {
        get {
            return DateValue.dateFormatter.date(from: currentValue)
        }
    }

    convenience init(withDate date:Date) {
        self.init(withString:DateValue.dateFormatter.string(from:date))
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

    override func dayOfWeekPressed() -> (String, CalcValue)? {
        guard let dv = dateValue else { return nil }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from:dv)
        let index = ((weekday - 1) + (calendar.firstWeekday - 1)) % 7
        return (calendar.shortWeekdaySymbols[index].uppercased(), CalcValue(withNumber:Double(index)))
    }

    func dateSubstrings() -> [String] {
        return currentValue.components(separatedBy: CharacterSet(charactersIn:CalcValue.dateSeparator))
    }

	override func slashPressed() -> Bool {
        return appendSeparator(sep:CalcValue.dateSeparator, strings:dateSubstrings())
    }

    override func appendNumber(_ newValue:String) -> Bool {
        // We are entering days/months. Max lengths are 2-2-4.
        // It's far more likely that 5 is a mistake to be pushed off than a real year.
        // Unless it's yyyy-mm-dd mode. In which case, grr.
        let strings = dateSubstrings()
        if strings.count == 1 {
            currentValue = appendDigit(strings[0], digit:newValue)
        } else if strings.count == 2 {
            let s1 = strings[0]
            let s2 = appendDigit(strings[1], digit:newValue)
            currentValue = [s1, s2].joined(separator:CalcValue.dateSeparator)
        } else {
            let s1 = strings[0]
            let s2 = strings[1]
            let s3 = appendDigit(strings[2], digit:newValue, max:4)
            currentValue = [s1, s2, s3].joined(separator:CalcValue.dateSeparator)
        }
        return true
	}
    override func canonicalizeDisplayString() {
        if let dv = dateValue {
            currentValue = DateValue.dateFormatter.string(from:dv)
        }
    }

    // MARK: Operators
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

    var secondSeparator = CalcValue.timeSeparator
    override var allowsColons : Bool {
        get {
            return true
        }
    }

    override func validate() -> Bool {
        // We only need to validate the last segment, previous ones got validated as they were entered.
        return validateLastSegment()
    }

    func timeSubstrings() -> [String] {
        return currentValue.components(separatedBy: CharacterSet(charactersIn: CalcValue.timeSeparator + secondSeparator))
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

    override func appendNumber(_ newValue:String) -> Bool {
        // We are entering minutes/seconds/hundredths. There can be only two.
        let strings = timeSubstrings()
        if strings.count == 3 {
            let h = strings[0]
            let m = strings[1]
            let s = appendDigit(strings[2], digit:newValue)
            currentValue = h + CalcValue.timeSeparator + m + secondSeparator + s
        } else if strings.count == 2 {
            let h = strings[0]
            let m = appendDigit(strings[1], digit:newValue)
            currentValue = h + CalcValue.timeSeparator + m
        } else {
            // This shouldn't get reached since it's not a Time until it has a separator,
            // so we don't have to worry about elapsed vs time of day limits.
            currentValue += newValue
        }
        return true
     }

    override func colonPressed() -> Bool {
        return appendSeparator(sep: CalcValue.timeSeparator, strings: timeSubstrings(), padZeros:true)
    }
}

class TimeOfDayValue : TimeValue {
	// Doc says making DateFormatters is expensive and should be static.
    // Changing Locale would give us ':' but not the proper AM/PM and leading zeros.
	static let timeFormatter :DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        // Don't show AM/PM; there's a label for that.
        if CalcValue.useShortForm {
            // Always ':'
            formatter.dateFormat = "J':'mm':'ss"
        } else {
            // Whatever's in the locale.
            formatter.setLocalizedDateFormatFromTemplate("J:mm:ss")
        }
        return formatter
    }()

    static let hourFormatter :DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.setLocalizedDateFormatFromTemplate("J")
        return formatter
    }()

    static let shortTimeFormatter :DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        // Don't show AM/PM; there's a label for that.
        if CalcValue.useShortForm {
            // Always ':'
            formatter.dateFormat = "J':'mm"
        } else {
            // Whatever's in the locale.
            formatter.setLocalizedDateFormatFromTemplate("J:mm")
        }
        return formatter
    }()

    override var isTimeOfDay: Bool {
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
        super.init(withString:TimeOfDayValue.timeFormatter.string(from:date))
        containsValue = true
        isPM = Calendar.current.component(Calendar.Component.hour, from: date) > 12
    }


    init(withElapsedTime value:ElapsedTimeValue) {
        super.init(withString:value.currentValue)
        containsValue = true
        let strings = timeSubstrings()
        if strings.count > 0 {
            isPM = (strings[0] as NSString).integerValue > 12
        }
        canonicalizeDisplayString()
    }

    init(withDecimalValue value:DecimalValue) {
        super.init(withString:value.currentValue)
        if let v = value.intValue {
            isPM = v > 12
        }
        canonicalizeDisplayString()
    }

    func timeComponents() -> DateComponents {
        let strings = timeSubstrings()
        var dc = DateComponents()
        if (strings.count > 0) {
            var h = (strings[0] as NSString).integerValue
            if isPM && h < 12 {
                h += 12
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

    override func validateCommand(_ type:CommandType) -> Bool {
        return type != .Multiply && type != .Divide
    }

    override func amPMPressed() -> Bool {
        isPM = !isPM
        return true
    }

	override func canonicalizeDisplayString() {
        let strings = timeSubstrings()
        var formatter :DateFormatter
        if let dv = dateValue {
            if strings.count == 3 {
                formatter = TimeOfDayValue.timeFormatter
            } else if strings.count == 2 {
                formatter = TimeOfDayValue.shortTimeFormatter
            } else {
                // This converts values > 12 if the locale requires it.
                formatter = TimeOfDayValue.hourFormatter
            }
            currentValue = formatter.string(from:dv)
        }
    }

    // MARK: Operators
    override func adding(_ right: AbstractValue) -> AbstractValue? {
        // elapsed + elapsed = elapsed. TOD + elapsed = TOD. TOD + TOD = Error.
        if let rightTI = right as? DecimalTimeValue { return self + rightTI }
        return nil
    }
    override func subtracting(_ right: AbstractValue) -> AbstractValue? {
        // elapsed - anything = elapsed. TOD - elapsed = TOD. TOD - TOD = elapsed
        if let rightTI = right as? DecimalTimeValue { return self - rightTI }
        if let rightTD = right as? TimeOfDayValue { return self - rightTD }
        return nil
    }
    static func +(left: TimeOfDayValue, right: DecimalTimeValue) -> AbstractValue? {
        // TOD + decimal = TOD. Elapsed + decimal = Elapsed.
        guard let rawLeft = left.dateValue else {return nil}
        let rawRight = right.timeIntervalValue
        return TimeOfDayValue(withDate:rawLeft + rawRight)
    }

    static func -(left: TimeOfDayValue, right: DecimalTimeValue) -> AbstractValue? {
        guard let rawLeft = left.dateValue else {return nil}
        let rawRight = right.timeIntervalValue
        return TimeOfDayValue(withDate:rawLeft - rawRight)
    }

    static func +(left: DecimalValue, right: TimeOfDayValue) -> AbstractValue? {
        guard let rawRight = right.dateValue else {return nil}
        let rawLeft = left.timeIntervalValue
        return TimeOfDayValue(withDate:rawRight + rawLeft)
    }

    static func -(left: TimeOfDayValue, right: TimeOfDayValue) -> AbstractValue? {
        guard let end = left.dateValue else {return nil}
        guard let start = right.dateValue else {return nil}
        if end < start {return nil}
        return ElapsedTimeValue(withTimeInterval:end.timeIntervalSince(start))
    }

}

class ElapsedTimeValue : TimeValue, DecimalTimeValue {

    var containsDecimalPoint = false
    var timeIntervalValue: TimeInterval {
        get {
            let comps = timeComponents()
            if containsDecimalPoint {
                return TimeInterval(comps[0] * 60 + comps[1]) + (Double(comps[2]) / 100)
            }
            return TimeInterval(comps[0] * 3600 + comps[1] * 60 + comps[2])
        }
    }

    // HP decimal time is in hours. TimeInterval is in seconds.
    var doubleValue: Double {
        get {
            return timeIntervalValue / 3600
        }
    }

    init?(withTimeInterval value:TimeInterval) {
        super.init()
        containsValue = true
        let h = lround(floor(value / 3600))
        if h >= CalcValue.maxHours {
            return nil
        }
        let m = lround(floor(value / 60)) % 60
        let s = lround(floor(value)) % 60
        let c = lround(value.truncatingRemainder(dividingBy: 1) * 100)
        containsDecimalPoint = (h == 0 && c > 0)
        currentValue = formatString(h: h, m: m, s: s, c: c)
    }

    init?(withDecimalValue value:DecimalValue) {
        if Int(value.doubleValue) >= CalcValue.maxHours {
            return nil
        }
        super.init(withString:value.currentValue)
        containsValue = true
    }

    func timeComponents() -> [Int] {
        let strings = timeSubstrings()
        let count = strings.count
        let h = count > 0 ? (strings[0] as NSString).integerValue : 0
        let m = count > 1 ? (strings[1] as NSString).integerValue : 0
        let s = count > 2 ? (strings[2] as NSString).integerValue : 0
        return [h, m, s]
    }

    // An elapsed time can become time if it doesn't have fractions of seconds.
    // Values over 24 hours just wrap.
    override var canChangeMode : Bool {
        get {
            return !containsDecimalPoint
        }
    }

    override func validateLastSegment() -> Bool {
        if containsDecimalPoint {
            // Format is m:s.c, and m has no upper bound.
            let strings = timeSubstrings()
            switch strings.count {
                case 2:
                    let m = strings[1]
                    return (m as NSString).integerValue < 60

                case 3:
                    let sec = strings[2]
                    return (sec as NSString).integerValue < 100

                default:
                    return true
            }
        } else {
            return super.validateLastSegment()
        }
    }

    // decimalPressed format - m:s.c. It does not support h:m:s.c
    override func decimalPressed(_ str:String) -> Bool {
        if !currentValue.contains(str) {
            secondSeparator = str
            let strings = timeSubstrings()
            if strings.count == 3 {
                return false
            }
            currentValue += str
            containsDecimalPoint = true
            return true
        }
        return false
    }

    func formatString(h:Int, m:Int, s:Int, c:Int) -> String {
        // If there are hundredths, ignore hours. It should be zero anyway. Minutes have no upper bound.
        // Otherwise use h:m:s format, no upper bound on hours.
        // DateFormatter assumes actual dates with upper bounds on h/m.
        // DateComponentsFormatter doesn't support hundredths.
        let s1 = CalcValue.timeSeparator
        if containsDecimalPoint {
            let s2 = CalcValue.decimalSeparator
            return String(format:"%i%@%02i%@%02i", arguments:[m, s1, s, s2, c])
        } else if (s > 0) {
            return String(format:"%i%@%02i%@%02i", arguments:[h, s1, m, s1, s])
        } else if (m > 0) {
            return String(format:"%i%@%02i", arguments:[h, s1, m])
        } else {
            return "\(h)"
        }
    }

    override func canonicalizeDisplayString() {
        let comps = timeComponents()
        if comps.count == 1 {
            // currentValue does not need modification.
            return
        }
        if containsDecimalPoint {
            let m = comps[0]
            let s = comps[1]
            let c = comps[2]
            currentValue = formatString(h:0, m:m, s:s, c:c)
        } else {
            let h = comps[0]
            let m = comps[1]
            let s = comps[2]
            currentValue = formatString(h:h, m:m, s:s, c:0)
        }
    }

    // MARK: Operators
    override func adding(_ right: AbstractValue) -> AbstractValue? {
        // elapsed + TIR = elapsed. TOD + elapsed = TOD.
        if let rightTI = right as? DecimalTimeValue { return (self as DecimalTimeValue) + rightTI }
        if let rightTD = right as? TimeOfDayValue { return rightTD + (self as DecimalTimeValue)}
        return nil
    }
    override func subtracting(_ right: AbstractValue) -> AbstractValue? {
        // elapsed - TIR = elapsed.
        // Chart also shows elapsed - TOD = elapsed. Maybe they're just ignoring the TOD press
        // and treating it like an elapsed time. For now, it's an error.
        if let rightTI = right as? DecimalTimeValue { return (self as DecimalTimeValue) - rightTI }
        return nil
    }
    // Multiply/Divide uses time in hours.
    override func multiplying(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self as DecimalTimeValue * rightDV }
        return nil
    }
    override func dividing(_ right: AbstractValue) -> AbstractValue? {
        if let rightDV = right as? DecimalValue { return self as DecimalTimeValue / rightDV }
        return nil
    }
}

class CalcValue: NSObject {

    // Small watch has 10 digits with a 15-point font, 9 with 16.
    // If 15 isn't readable enough, make the max conditional.
    // Also make sure date is limited to 2-digit years.
    static let maxDigits : Int = 10
    // maxHours to avoid overflow with full ElapsedTime format.
    static let maxHours : Int = 10000

    static var timeSeparator = ":"
    static var dateSeparator = "/"
    static var decimalSeparator = "."
    static var useShortForm = false
    
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

    var allowsPercent: Bool {
        get {
            return calcValue.allowsPercent
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
        calcValue = TimeOfDayValue.init(withDate:date)
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

    func numberPressed(_ value: Int) -> Bool {
        return calcValue.numberPressed(value)
    }

    func applyPercent(_ pct : CalcValue) -> CalcValue? {
        if let result = calcValue.applyPercent(pct.calcValue) {
            return CalcValue(withValue:result)
        }
        return nil
    }

    func plusMinusPressed() -> Bool {
        return calcValue.plusMinusPressed()
    }

    func dayOfWeekPressed() -> (String, CalcValue)? {
        return calcValue.dayOfWeekPressed()
    }

    func decimalPressed() -> Bool {
        return calcValue.decimalPressed(CalcValue.decimalSeparator)
    }

    // Typing colon changes decimal mode to elapsed time.
    func colonPressed() -> Bool {
        if !calcValue.allowsColons && !calcValue.canBecomeElapsedTime {
            return false
        }
        // It's elapsed time unless T or AM is pressed.
        if let dv = calcValue as? DecimalValue {
            // Integers become first segment of elapsed time.
            if dv.intValue != nil {
                guard let result = ElapsedTimeValue(withDecimalValue:dv) else {return false}
                calcValue = result
            } else {
                // Don't add a colon; it already has one from the fraction.
                guard let result = ElapsedTimeValue(withTimeInterval:dv.timeIntervalValue) else {return false}
                calcValue = result
                return true
            }
        }
        return calcValue.colonPressed()
    }

    // Typing Time or AM changes the mode to time, if it's an integer or elapsedTime.
    func makeTimeOfDay() -> Bool {
        if calcValue.isTimeOfDay { return true }
        if !calcValue.allowsColons && !calcValue.canChangeMode {
            return false
        }
        if let dv = calcValue as? DecimalValue {
            if dv.containsValue {
                calcValue = TimeOfDayValue(withDecimalValue:dv)
            } else {
                calcValue = TimeOfDayValue(withDate:Date())
            }
            return true
        } else if let tv = calcValue as? ElapsedTimeValue {
            calcValue = TimeOfDayValue(withElapsedTime:tv)
            return true
        }
        return false
    }

    func amPMPressed() -> Bool {
        if makeTimeOfDay() {
            return calcValue.amPMPressed()
        }
        return false
    }
    // If it's already time, convert to TimeOfDay
    func timePressed() -> Bool {
        // If we start with a decimal, add a colon as a shortcut. If it's ElapsedTime we already have one.
        if calcValue is DecimalValue {
            let needsColon = calcValue.containsValue
            if makeTimeOfDay() {
                if needsColon {
                    return calcValue.colonPressed()
                }
                return true
            }
            return false
        }
        return makeTimeOfDay()
    }

    // Typing slash changes the mode to date, if it's an integer.
    func slashPressed() -> Bool {
        if !calcValue.allowsSlash && !calcValue.canChangeMode {
            return false
        }
        // Make a date value.
        if !calcValue.allowsSlash {
            calcValue = DateValue(withString:calcValue.currentValue)
        }
        return calcValue.slashPressed()
    }

    func canonicalizeDisplayString() {
        calcValue.canonicalizeDisplayString()
    }

    // MARK: Operators
    // d: decimal
    // t: ElapsedTime
    // T: TimeOfDay
    // D: Date

    // d op d = d
    // d + t = t, d + T = T, d + D = Err
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