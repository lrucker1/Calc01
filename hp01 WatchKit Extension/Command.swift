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
    var mode: CalculatorMode
    let leftValue: Double
    let leftDate: Date?

    init(type: CommandType, leftValue: Double)
    {
        self.type = type
        self.leftValue = leftValue
        self.leftDate = nil
        self.mode = .Calculator
        super.init()
    }

    init(type: CommandType, leftTime: Date?)
    {
        self.type = type
        self.leftValue = 0
        self.leftDate = leftTime
        self.mode = .Time
        super.init()
    }

    override var debugDescription: String {
        get {
            var str = "?"
            switch type {
                case .Divide: str = "÷"
                case .Multiply: str = "×"
                case .Subtract: str = "-"
                case .Add: str = "+"
            }
            return leftValue.debugDescription + " " + str
        }
    }

    func executeWithNewValue(newValue: Double) -> Double
    {
        // += means lv + lv, *= means lv * lv, etc
        var result = leftValue
        
        switch type
        {
        case .Divide: result /= newValue
        case .Multiply: result *= newValue
        case .Subtract: result -= newValue
        case .Add: result += newValue
        }
        
        return result
    }


    func executeWithTime(newValue: DateComponents) -> Date?
    {
        let date = leftDate ?? Date()

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
