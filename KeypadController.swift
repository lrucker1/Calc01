//
//  KeypadController.swift
//  RetroCalc
//
//  Created by Lee Ann Rucker on 8/25/17.
//  Copyright © 2017 Lee Ann Rucker. All rights reserved.
//

// These shenanigans confuse IB; you may have to change the KeypadController's class
// back to Interface/View to wire up UI elements.
#if os(watchOS)
import WatchKit
class KeypadParent:InterfaceController {}
#else
import UIKit
class KeypadParent:ViewController {}
#endif

class KeypadController: KeypadParent {
    var calcValue = CalcValue() {
        didSet {
            showingCurrentTime(calcValue.isCurrentTime)
        }
    }
    var resetValue = CalcValue()
    var memoryValue = CalcValue() // Do not initialize until the formatter dependencies are set.
    var uses24HourTime = false
    var command: Command? {
        didSet {
            setOperatorLabel(command == nil ? "" : command!.operatorSymbol)
        }
    }
    var calculationExecuted = false

    override func configure(timeFormatter: DateFormatter, useShortForm:Bool = false) -> (is24:Bool, timeSep:String, dateSep:String) {
        timeFormatter.setLocalizedDateFormatFromTemplate("j")
        // If 'H' or 'k', it's 24 hour time.
        if let df = timeFormatter.dateFormat {
            uses24HourTime = df.rangeOfCharacter(from: CharacterSet(charactersIn:"Hk")) != nil
        }
        timeFormatter.dateStyle = .short
        var dComps : [String] = []
        let dateOrder = "Mdy"
        timeFormatter.setLocalizedDateFormatFromTemplate(dateOrder)
        var str = timeFormatter.dateFormat ?? dateOrder
        let cs = CharacterSet(charactersIn:dateOrder)
        for ch in str.unicodeScalars {
            if cs.contains(ch) {
                dComps.append(String(ch))
            }
        }
        CalcValue.dateOrder = dComps

        // Locale does not give us date or time seps. Yes, there are languages that don't use : for times.
        // Fortunately everyone seems to use different ones for date, time, decimal.
        // Germany and Denmark regions are good for testing.
        timeFormatter.dateStyle = .short
        timeFormatter.timeStyle = .none
        str = timeFormatter.string(from:Date())
        var dateSep = "/"
        var timeSep = ":"
        var decimalSep = "."

        if (useShortForm) {
            // 7-segment displays do not have '/'
            dateSep = "-"
        } else {
            decimalSep = Locale.current.decimalSeparator ?? decimalSep
            for ch in str.unicodeScalars {
                if !CharacterSet.decimalDigits.contains(ch) {
                    dateSep = String(ch)
                    break
                }
            }
            timeFormatter.dateStyle = .none
            timeFormatter.timeStyle = .short
            // Make sure there are no AM/PM strings.
            timeFormatter.setLocalizedDateFormatFromTemplate("J:mm")
            str = timeFormatter.string(from:Date())

            for ch in str.unicodeScalars {
                if !CharacterSet.decimalDigits.contains(ch) {
                    timeSep = String(ch)
                    break
                }
            }
        }
        CalcValue.dateSeparator = dateSep
        CalcValue.decimalSeparator = decimalSep
        CalcValue.timeSeparator = timeSep
        CalcValue.useShortForm = useShortForm
        CalcValue.uses24HourTime = uses24HourTime
        memoryValue = CalcValue.loadFromMemory()

        setOperatorLabel("")
        setDisplayValue()
        return (uses24HourTime, timeSep, dateSep)
    }

	override func updateDisplay() {
        // Redisplay the updated currentTime.
        if calcValue.isCurrentTime {
            calcValue.canonicalizeDisplayString()
            setDisplayValue()
        }
    }

    func blink() {
        blinkDisplay(false);
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.blinkDisplay(true);
        }
    }

    func doubleBlink() {
        blinkDisplay(false);
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.blinkDisplay(true);
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.blinkDisplay(false);
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.blinkDisplay(true);
                }
            }
        }
    }

    func setDisplayValue() {
        setDisplayValue(value:calcValue)
    }

    // Use this only for results that are not values, like DayOfWeek
    func setDisplayValue(string: String ) {
        setDisplayLabel(withAlphanumericString:string)
        setAMPMState(isTimeOfDay:false)
    }

    func setDisplayValue(value: CalcValue) {
        setDisplayLabel(value.stringValue)
        setAMPMState(isTimeOfDay:value.isTimeOfDay, isPM:value.isPM, uses24HourTime:uses24HourTime)
    }

    func numberPressed(_ value: Int) {

        // Stop repeating commands when a new number is pressed.
        if calculationExecuted {
            command = nil
            calculationExecuted = false
            calcValue = CalcValue()
        }

        handleTapResult(calcValue.numberPressed(value))
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
            if (!calcValue.containsValue) {
                command!.type = type
                blink()
                return
            }
            // If the previous calculation has never been executed, do so now.
            if !executeCommand() {
                return
            }
        }
        blink()
        command = Command(type:type, leftValue:calcValue)
        setOperatorLabel(command!.operatorSymbol)
        calcValue = CalcValue()
        calculationExecuted = false
    }

    // This will do double-blinks but not blinks, as we don't want an extra one
    // when finishing an intermediate command in commandTapped.
    func executeCommand() -> Bool {
        // A command needs a second value unless it's repeatable: *=, +=
        if !calcValue.containsValue && !command!.canRepeat {
            // It's a no-op, not an error.
            return true
        }
        // If nothing has been entered the first time it's run, use the leftValue
        // This makes ?= mean "lv ? lv"
        // These commands can repeat.
        guard let cmd = command else {return false}
        var commandValue = calcValue
        if !calcValue.containsValue && !calculationExecuted {
            commandValue = cmd.leftValue
            cmd.repeating = true
        }
        let answer = cmd.executeWithNewValue(newValue:commandValue)
        if answer == nil {
            doubleBlink()
            return false
        }
        resetValue = calcValue
        calcValue = answer!
        setDisplayValue()
        calculationExecuted = true
        if !cmd.repeating {
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
            blink()
        } else if executeCommand() {
            blink()
        }
    }

    @IBAction func clearTapped() {
        // If there's a command and a second number, clear just the second number,
        // leave the command intact. Changing operators will change the command.
        // If there's no second number, clear everything.
        showingCurrentTime(false)
        if command != nil {
            if calcValue.containsValue {
                // Leave the command, just clear the second number and re-show the first.
                calcValue = CalcValue()
                setDisplayValue(value:command!.leftValue)
                blink()
                return
            } else {
                // Clear the command and the first number.
                command = nil
            }
        }
        calcValue = CalcValue()
        handleTapResult(true)
    }

    func handleTapResult(_ success: Bool) {
        showingCurrentTime(calcValue.isCurrentTime)
        if success {
            setDisplayValue()
            blink()
        } else {
            doubleBlink()
        }
    }
    @IBAction func percentTapped() {
        if let result = executePercent() {
            calcValue = result
            handleTapResult(true)
        } else {
            handleTapResult(false)
        }
    }

    func executePercent() -> CalcValue? {
        // Percent needs a second value unless it's repeatable: *=, +=
        if !calcValue.containsValue {
            return nil
        }
        guard let cmd = command else {return nil}
        let leftValue = cmd.leftValue
        return leftValue.applyPercent(calcValue)
    }

    @IBAction func decimalTapped() {
        handleTapResult(calcValue.decimalPressed())
    }

    @IBAction func plusMinusTapped() {
        handleTapResult(calcValue.plusMinusPressed())
    }

    @IBAction func colonTapped() {
        handleTapResult(calcValue.colonPressed())
    }

    @IBAction func slashTapped() {
        handleTapResult(calcValue.slashPressed())
    }

    @IBAction func amPMTapped() {
       handleTapResult(calcValue.amPMPressed())
	}

    @IBAction func dayOfWeekTapped() {
        if let dowStr = calcValue.dayOfWeekPressed() {
            calculationExecuted = true
            // The value will be numeric, just like the calculator, and tapping '=' will show it.
            // But let's have some fun with L10N.
            // TODO: Either strip diacritics or have the UI use System font. DSEG doesn't have 'em.
            calcValue = dowStr.1
            setDisplayValue(string:dowStr.0)
            blink()
            showingCurrentTime(false)
        } else {
            doubleBlink()
       }
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

    // amPM turns elapsedTime into Time. Time button just shows the time.
    @IBAction func timeTapped() {
        calcValue = CalcValue(withCurrentTime:Date())
        if calculationExecuted {
            command = nil
            calculationExecuted = false
        }
        handleTapResult(true)
    }

    @IBAction func dateTapped() {
        resetValue = calcValue
        calcValue = CalcValue(withDate:Date())
        if calculationExecuted {
            command = nil
            calculationExecuted = false
        }
        handleTapResult(true)
    }

    @IBAction func swapTapped() {
        if command == nil || !calcValue.containsValue {
            handleTapResult(false)
            return
        }
        let cmd = command!
        let tmp = cmd.leftValue
        command = Command(type:cmd.type, leftValue:calcValue)
        calcValue = tmp
        handleTapResult(true)
    }

    @IBAction func timeToDecimalTapped() {
        handleTapResult(calcValue.timeToDecimalPressed())
    }

    @IBAction func decimalToTimeTapped() {
        handleTapResult(calcValue.decimalToTimePressed())
    }

    @IBAction func memoryTapped() {
        calcValue = memoryValue.copy() as! CalcValue
        handleTapResult(true)
    }

    @IBAction func storeMemoryTapped() {
        // Can't store partial values.
        if !calcValue.validate() {
            doubleBlink()
            return
        }
        // If there's a pending calculation, finish it.
        if command != nil && !calculationExecuted {
            if !executeCommand() {
                doubleBlink()
                return
            }
        }
        memoryValue = calcValue.copy() as! CalcValue
        calcValue.storeMemory()
        handleTapResult(true)
    }

    @IBAction func resetTapped() {
        calcValue = resetValue.copy() as! CalcValue
        handleTapResult(true)
    }

}
