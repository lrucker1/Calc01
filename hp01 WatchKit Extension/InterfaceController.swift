//
//  InterfaceController.swift
//  hp01 WatchKit Extension
//
//  Created by Lee Ann Rucker on 8/8/17.
//  Copyright © 2017 Lee Ann Rucker. All rights reserved.
//
// TODO: Automatic constant: save the command and the right-value: xx?yy=, zz= becomes zz?yy=
// Allow hundreths of seconds? DateComponent would take it as nano. Format is MM:SS.CC, no HH
// Colon turns it into a time interval, T key makes it a time of day. ToD is displayed as "HH:MM SS"

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {
    @IBOutlet weak var displayLabel: WKInterfaceLabel!
    @IBOutlet weak var operatorLabel: WKInterfaceLabel!

    var calcValue = CalcValue()
    var resetValue = CalcValue()
    var timeFormatter = DateFormatter()
    var command: Command? {
        didSet {
            operatorLabel.setText(command == nil ? "" : command!.operatorSymbol)
        }
    }
    var calculationExecuted = false

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .medium
        operatorLabel.setText("")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    // Slow single blink for successful entry, fast double blink for error.
    func setTextColors(_ color: UIColor) {
        displayLabel.setTextColor(color);
        operatorLabel.setTextColor(color);
    }

    func blink() {
        setTextColors(UIColor.black);
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setTextColors(UIColor.red);
        }
    }

    func doubleBlink() {
        setTextColors(UIColor.black);
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.setTextColors(UIColor.red);
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.setTextColors(UIColor.black);
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.setTextColors(UIColor.red);
                }
            }
        }
    }

    func numberPressed(_ value: Int) {
        blink();

        // Stop repeating commands when a new number is pressed.
        if calculationExecuted {
            command = nil
            calculationExecuted = false
        }

        calcValue.numberPressed(value)
        setDisplayValue()
    }

    func setDisplayValue(value: CalcValue ) {
        displayLabel.setText(value.stringValue)
    }

    func setDisplayValue() {
        displayLabel.setText(calcValue.stringValue)
    }

    func setDisplayTime(value: Date) {
        displayLabel.setText(timeFormatter.string(from:value))
    }

    func commandTapped(_ type: CommandType) {
        if !calcValue.validate(type) {
            doubleBlink()
            return;
        }
        // If we have an existing command that hasn't run yet,
        // if the number hasn't changed, modify the command. Otherwise run it.
        // If it succeeds, carry on with the new one.
        if command != nil && !calculationExecuted {
            if (!calcValue.valueChanged) {
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
        command = Command(type:type, leftValue:calcValue)
        operatorLabel.setText(command!.operatorSymbol)
        calcValue = CalcValue()
        calculationExecuted = false
    }

    func executeCommand() -> Bool {
        // TODO: Make "repeating" a state on Command.
        // A command needs a second value unless it's repeatable: *=, +=
        if !calcValue.valueChanged && !command!.canRepeat {
            // It's a no-op, not an error.
            return true
        }
        // If nothing has been entered the first time it's run, use the leftValue
        // This makes ?= mean "lv ? lv"
        var commandValue = calcValue
        if !calcValue.valueChanged && !calculationExecuted {
            commandValue = command!.leftValue
        }
        let answer = command!.executeWithNewValue(newValue:commandValue)
        if answer == nil {
            doubleBlink()
            return false
        }
        resetValue = calcValue
        calcValue = answer!
        setDisplayValue()
        calculationExecuted = true
        if !command!.canRepeat {
            command = nil
        }
        return true
    }

    @IBAction func answerTapped() {
        if !calcValue.validate() {
            doubleBlink()
            return;
        }
        if command == nil {
            calcValue.canonicalizeDisplayString()
            setDisplayValue()
        } else if executeCommand() {
            blink()
        }
    }

    @IBAction func clearTapped() {
        // If there's a command and a second number, clear just the second number,
        // leave the command intact. Changing operators will change the command.
        // If there's no second number, clear everything.
        if command != nil {
            if calcValue.valueChanged {
                // Leave the command, just clear the second number and show the first.
                setDisplayValue(value:command!.leftValue)
                return
            } else {
                // Clear the command and the first number.
                command = nil
            }
        }
        calcValue = CalcValue()
        setDisplayValue()
    }

    func handleTapResult(_ success: Bool) {
        if success {
            blink()
            setDisplayValue()
        } else {
            doubleBlink()
        }
    }
    @IBAction func percentTapped() {
        handleTapResult(calcValue.percentPressed())
    }

    @IBAction func decimalTapped(sender: WKInterfaceButton) {
        handleTapResult(calcValue.decimalPressed("."))
    }

    @IBAction func plusMinusTapped() {
        handleTapResult(calcValue.plusMinusPressed())
    }

    @IBAction func colonTapped() {
        handleTapResult(calcValue.colonPressed())
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

    // TODO: if there's a timeElapsed, turn it into a timeOfDay
    @IBAction func timeTapped() {
        blink();
        resetValue = calcValue
        calcValue = CalcValue(withDate:Date())
        setDisplayValue()
        command = nil
    }

    @IBAction func resetTapped() {
        blink();
        calcValue = resetValue
        setDisplayValue()
        command = nil
    }
}
