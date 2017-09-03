//
//  Command.swift
//  Calc
//
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
    var repeating = false
    let leftValue: CalcValue

    init(type: CommandType, leftValue: CalcValue) {
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

    func executeWithNewValue(newValue: CalcValue) -> CalcValue? {
        switch type {
            case .Divide: return leftValue / newValue
            case .Multiply: return leftValue * newValue
            case .Subtract: return leftValue - newValue
            case .Add: return leftValue + newValue
        }
    }
}
