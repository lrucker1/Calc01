//
//  Command.swift
//  Calc
//
//  Created by Jonas Treub on 10/12/14.
//  Copyright (c) 2014 Noodlewerk. All rights reserved.
//

import UIKit

enum CommandType
{
    case Divide
    case Multiply
    case Subtract
    case Add
}

class Command: NSObject
{
    var type: CommandType
    let leftValue: CalcValue

    init(type: CommandType, leftValue: CalcValue)
    {
        self.type = type
        self.leftValue = leftValue
        super.init()
    }

    override var debugDescription: String {
        get {
            return leftValue.debugDescription + " " + operatorSymbol
        }
    }

    var operatorSymbol : String {
        get {
            switch type {
                case .Divide: return "÷"
                case .Multiply: return "×"
                case .Subtract: return "-"
                case .Add: return "+"
            }

        }
    }

    var canRepeat : Bool {
        get {
            if !leftValue.canRepeatCommands { return false }
            switch type {
                case .Multiply, .Add: return true
                default : return false
            }

        }
    }

    func executeWithNewValue(newValue: CalcValue) -> CalcValue?
    {
        if let number = newValue.rawValue as? Double {
            return executeWithNewValue(newValue:number)
        }
        if let dc = newValue.rawValue as? DateComponents {
            return executeWithTime(newValue:dc)
        }
        return nil
    }

    func executeWithNewValue(newValue: Double) -> CalcValue?
    {
        if var result = leftValue.rawValue as? Double {
        
            switch type
            {
            case .Divide: result /= newValue
            case .Multiply: result *= newValue
            case .Subtract: result -= newValue
            case .Add: result += newValue
            }

            return CalcValue.init(withNumber:result)
        }
        let dc = DateComponents.init(hour:Int(newValue))
        return executeWithTime(newValue:dc)
    }

    func executeWithTime(newValue: DateComponents) -> CalcValue?
    {
        if let date = executeDateWithTime(newValue:newValue) {
             return CalcValue.init(withDate:date)
        }
        return nil
    }

    // Not all operations apply to dates.
    func executeDateWithTime(newValue: DateComponents) -> Date?
    {
        guard let dc = leftValue.rawValue as? DateComponents else { return nil }
        guard let date = Calendar.current.date(from:dc) else { return nil }

        switch type
        {
        case .Subtract:
            let h = newValue.hour ?? 0
            let m = newValue.minute ?? 0
            let s = newValue.second ?? 0
            let reverseDate = DateComponents.init(hour:-h, minute:-m, second:-s)
            return Calendar.current.date(byAdding:reverseDate, to:date)
        case .Add:
            return Calendar.current.date(byAdding:newValue, to:date)
        default:
            return nil
        }
    }

}
