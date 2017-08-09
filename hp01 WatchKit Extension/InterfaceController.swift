//
//  InterfaceController.swift
//  hp01 WatchKit Extension
//
//  Created by Lee Ann Rucker on 8/8/17.
//  Copyright © 2017 Lee Ann Rucker. All rights reserved.
//

import WatchKit
import Foundation

enum CalculatorMode
{
    case Calculator
    case Time
}

class InterfaceController: WKInterfaceController {
    var currentValue: String = "0"
    var valueChanged = false
    var resetValue: Double = 0
    var command: Command?
    var mode: CalculatorMode = .Calculator
    var calculationExecuted = false

    var currentDoubleValue: Double {
        get {
            return (currentValue as NSString).doubleValue
        }
    }

    @IBOutlet weak var displayLabel: WKInterfaceLabel!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func blink() {
        displayLabel.setTextColor(UIColor.black);
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.displayLabel.setTextColor(UIColor.red);
        }
    }

    func doubleBlink() {
        displayLabel.setTextColor(UIColor.black);
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.displayLabel.setTextColor(UIColor.red);
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.displayLabel.setTextColor(UIColor.black);
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.displayLabel.setTextColor(UIColor.red);
                }
            }
        }
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

    func numberPressed(_ value: Int) {
        blink();
        let newValue = "\(value)"
        valueChanged = true

        // Stop repeating commands when a new number is pressed.
        if calculationExecuted {
            command = nil
        }
        if currentValue == "0" || calculationExecuted {
            calculationExecuted = false
            currentValue = newValue
        } else if currentValue.contains(":") {
            // We are entering minutes/seconds. There can be only two.
            let strings = timeSubstrings()
            if strings.count == 3 {
                let h = strings[0]
                let m = strings[1]
                var s = strings[2] + newValue
                if s.count > 2 {
                    let end = s.index(s.endIndex, offsetBy:-2)
                    s = s.substring(from:end)
                }
                currentValue = h + ":" + m + ":" + s
            } else if strings.count == 2 {
                let h = strings[0]
                var m = strings[1] + newValue
                if m.count > 2 {
                    let end = m.index(m.endIndex, offsetBy:-2)
                    m = m.substring(from:end)
                }
                currentValue = h + ":" + m
            } else {
                currentValue += newValue
            }
        } else  {
            currentValue += newValue
        }

        displayLabel.setText(currentValue)
    }

    func setDisplayValue(value: Double) {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            // our value is an integer
            currentValue = "\(Int(value))"
        } else {
            // our value is a float
            currentValue = "\(value)"
        }

        displayLabel.setText(currentValue)
    }

    func setDisplayTime(value: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        displayLabel.setText(dateFormatter.string(from:value))
    }

    func commandTapped(_ type: CommandType) {
        if !validateTime() {
            doubleBlink()
            return;
        }
        // If we have an existing command that hasn't run yet,
        // if the number hasn't changed, modify the command. Otherwise run it.
        // If it succeeds, carry on with the new one.
        if command != nil && !calculationExecuted {
            if (!valueChanged) {
                command!.type = type
                blink()
                return
            }
            // If the previous calculation has never been executed, do so now.
            if !executeCommand() {
                doubleBlink()
                return
            }
        }
        blink()
        if mode == .Calculator {
            command = Command(type:type, leftValue:currentDoubleValue)
        } else {
            // Use the current time if the user hasn't entered anything.
            var leftTime : Date? = nil
            if valueChanged {
                leftTime = Calendar.current.date(from:timeComponents())
            }
            command = Command(type:type, leftTime:leftTime)
        }
        currentValue = "0"
        valueChanged = false
        calculationExecuted = false
    }

    func executeCommand() -> Bool {
         // Don't clear commands so we can repeat them.
         if (mode == .Calculator) {
            // If nothing has been entered the first time it's run, use the leftValue
            // This makes ?= mean "lv ? lv"
            var commandValue = currentDoubleValue
            if !valueChanged && !calculationExecuted {
                commandValue = command!.leftValue
            }
            let answer = command!.executeWithNewValue(newValue:commandValue)
            setDisplayValue(value:answer)
        } else {
            // Just add and subtract. Others are meaningless and return nil.
            let answer = command!.executeWithTime(newValue:timeComponents())
            if answer == nil {
                doubleBlink()
                return false
            } else {
                setDisplayTime(value:answer!)
            }
        }
        resetValue = currentDoubleValue
        calculationExecuted = true
        valueChanged = false
        return true
    }

    @IBAction func answerTapped() {
        if !validateTime() {
            doubleBlink()
            return;
        }
        if command != nil {
            if executeCommand() { blink() }
        } else if mode == .Time && currentValue.count > 0 {
            // Canonicalize the entered time.
            if let date = Calendar.current.date(from:timeComponents()) {
                setDisplayTime(value:date)
            }
        }
    }


    @IBAction func clearTapped() {
        // If there's a command and a second number, clear just the second number,
        // leave the command intact. Changing operators will change the command.
        // If there's no second number, clear everything.
        if command != nil {
            if valueChanged {
                // Leave the command, just clear the second number and show the first.
                valueChanged = false
                setDisplayValue(value:command!.leftValue)
                return
            } else {
                // Clear the command and the first number.
                command = nil
            }
        }
        currentValue = "0"
        displayLabel.setText(currentValue)
    }

    func validateTime() -> Bool {
        if mode != .Time { return true }
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

    @IBAction func percentTapped() {
        if mode == .Time {
            doubleBlink()
            return;
        }
        blink();
        let value = currentDoubleValue / 100
        setDisplayValue(value: value)
    }

    @IBAction func decimalTapped() {
        if mode == .Time {
            doubleBlink()
            return
        }
        blink();
        if !currentValue.contains(".") {
            currentValue += "."
            displayLabel.setText(currentValue)
        }
    }

    @IBAction func colonTapped() {
        if currentValue.contains(":") {
            let strings = timeSubstrings()
            // If we have two colons already, or the time segment is out of range, it's an error.
            if strings.count == 3 || !validateTime() {
                doubleBlink()
                return;
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
        blink();
        currentValue += ":"
        mode = .Time
        displayLabel.setText(currentValue)
        valueChanged = true
        calculationExecuted = false
    }

    //MARK: number buttons

    @IBAction func button0tapped() {
        numberPressed(0)
    }

    @IBAction func button1Tapped() {
        numberPressed(1)
    }

    @IBAction func button2Tapped() {
        numberPressed(2)
    }

    @IBAction func button3Tapped() {
        numberPressed(3)
    }

    @IBAction func button4Tapped() {
        numberPressed(4)
    }

    @IBAction func button5Tapped() {
        numberPressed(5)
    }

    @IBAction func button6Tapped() {
        numberPressed(6)
    }

    @IBAction func button7Tapped() {
        numberPressed(7)
    }

    @IBAction func button8Tapped() {
        numberPressed(8)
    }

    @IBAction func button9Tapped() {
        numberPressed(9)
    }

    //MARK: command buttons

    @IBAction func addTapped() {
        commandTapped(.Add)
    }

    @IBAction func subtractTapped() {
        commandTapped(.Subtract)
    }

    @IBAction func multiplyTapped() {
        commandTapped(.Multiply)
    }

    @IBAction func divideTapped() {
        commandTapped(.Divide)
    }

    @IBAction func timeTapped() {
        blink();
        if mode == .Calculator {
            mode = .Time
            resetValue = currentDoubleValue
            setDisplayTime(value:Date())
            currentValue = "0"
            valueChanged = false
            command = nil
        }
    }

    @IBAction func resetTapped() {
        blink();
        if mode == .Time {
            mode = .Calculator
            setDisplayValue(value:resetValue)
            valueChanged = false
            command = nil
        }
    }
}
