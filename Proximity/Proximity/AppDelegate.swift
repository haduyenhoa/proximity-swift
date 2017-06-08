//
//  AppDelegate.swift
//  Proximity
//
//  Created by Duyen Hoa Ha on 31/03/2015.
//  Copyright (c) 2015 HA Duyen Hoa. All rights reserved.
//

import Cocoa
import IOBluetoothUI
import IOKit
import CoreBluetooth

enum BPStatus {
    case inRange
    case outRange
}

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var bluetoothManager : CBPeripheralManager?
    var device : IOBluetoothDevice?
    var password :String = ""
    var username : String = ""
    var statusItem : NSStatusItem?
    var timer : Timer?
    var timerInterval : TimeInterval = 60
    var screenIsLocked = false
    
    var priorStatus : BPStatus =  BPStatus.outRange
    var isRunningScript = false
    var isCheckingRSSI = false
    
    
    var enableMonitoring = false
    
    @IBOutlet weak var cbShowPassword: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        //load password to create script
        let defaults = UserDefaults.standard
        password = defaults.string(forKey: "password") ?? ""
        
        NSApplication.shared.windows.first?.delegate = self
        
        let center = DistributedNotificationCenter.default()
        center.addObserver(self, selector: #selector(AppDelegate.screenLocked), name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"), object: nil)
        center.addObserver(self, selector: #selector(AppDelegate.screenUnlocked), name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"), object: nil)
        
        createMenuBar()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    //MARK: Helps
    func isInRange() -> Bool{
        return device != nil && device?.remoteNameRequest(nil) == kIOReturnSuccess
    }
    
    //TODO: if screen unlocked but we are not in range, send a notification to apple watch?
    @objc func screenLocked() {
        screenIsLocked = true
        NSLog("Screen is locked")
    }
    
    @objc func screenUnlocked() {
        screenIsLocked = false
        NSLog("Screen is unlocked")
    }
    
    
    func createMenuBar() {
        //create Menu
        let menu = NSMenu()
        
        //button preferences
        menu.addItem(withTitle: "Preferences", action: #selector(AppDelegate.showPreferences), keyEquivalent: "")
        
        //btn quit
        menu.addItem(withTitle: "Quit", action: #selector(AppDelegate.terminate), keyEquivalent: "")
        
        statusItem = NSStatusBar.system.statusItem(withLength: -1)
        
        statusItem?.highlightMode = true
        statusItem?.menu = menu
        
        setMenuIcon(BPStatus.outRange)
    }
    
    func getInRangeScript() -> NSAppleScript {
        //wake up
        var assertionID = IOPMAssertionID()
        let str : CFString = "" as CFString
        _ =  IOPMAssertionDeclareUserActivity(str, kIOPMUserActiveLocal, &assertionID)
        
        let scriptObject = NSAppleScript(source:
            "on run\n"
//            + "tell application \"System Events\"\n"
//            + "tell process \"Finder\"\n"
//            + "key space\n"
//            + "end tell\n"
//            + "end tell\n"
            +
                "tell application \"/System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app\" to quit\n"
//            + "tell application \"System Events\" to key code 53\n"

            + "delay 4.0\n"
            + "tell application \"System Events\" to keystroke \"" + (password) + "\"\n"
            + "delay 0.5\n"
            + "tell application \"System Events\" to keystroke return\n"
            + "end run\n"

            
                /*
            // got error: System Events got an error: Proximity is not allowed assistive access
            
            + "tell application \"System Events\" to tell process \"loginwindow\" to entire contents\n"
            + "tell application \"System Events\" to tell process \"loginwindow\"\n"
            + "tell window \"Login Panel\"\n"
            + "if name of static text 1 is \""+username+"\" then\n"
            + "set value of text field 1 to \""+password+"\"\n"
            + "keystroke return\n"
            + "end if\n"
            + "end tell\n"
            + "end tell\n"
            + "end run\n"
*/
        )
        
        return scriptObject!
    }
    
    func getOutRangeScript() -> NSAppleScript {
        //put pac to sleep without any thing
//        let pmsetTask = NSTask()
//        pmsetTask.launchPath = "/usr/bin/pmset"
//        pmsetTask.arguments = ["sleepnow"]
//        pmsetTask.launch()
        
        let scriptObject = NSAppleScript(source:
            "on run \ntell application \"System Events\" \n" +
            "start current screen saver \n" +
            "end tell \n" +
            "end run"
        )
        return scriptObject!
    }
    
    //MARK: Menu action
    @objc func showPreferences() {
        NSApplication.shared.windows.first?.makeKeyAndOrderFront(self)
        NSApplication.shared.windows.first?.orderFrontRegardless()
        NSApplication.shared.windows.first?.center()
    }
    
    @objc func terminate() {
        NSApplication.shared.terminate(self)
    }
    
    func startMonitoring() {
        if screenIsLocked {
            timer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(AppDelegate.handleTimer), userInfo: nil, repeats: true)
        } else {
            timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(AppDelegate.handleTimer), userInfo: nil, repeats: true)
        }
        
    }
    
    @objc func handleTimer() {
        var scriptObject : NSAppleScript?
        
        DispatchQueue(label: "com.haduyenhoa.service.bluetooth", attributes: []).async(execute: {
            if self.isInRange() {
                if self.priorStatus == BPStatus.outRange {
                    self.priorStatus = BPStatus.inRange
                }

                var rssi: BluetoothHCIRSSIValue = 127 //valid range: -127 to +20
                if self.device != nil { //sur that device is not nil
                    //try to connect
                    if self.isCheckingRSSI {
                        NSLog("Someone is checking the rssi")
                    } else {
                        if !(self.device!.isConnected()) {
                            self.device?.openConnection()
                        }

                        if (self.device!.isConnected()) {
                            rssi = self.device!.rawRSSI()
                            self.device?.closeConnection()
                            print("got RSSI: \(rssi)")
                        }

                        if (self.screenIsLocked && (rssi > -50)
                            ) {
                            NSLog("Device in Range")
                            scriptObject = self.getInRangeScript()
                        } else if !self.screenIsLocked && (rssi <= -50) {
                            NSLog("Bluetooth is not near by my Mac. Log out")
                            scriptObject = self.getOutRangeScript()
                        } else {
//                            print("nothing to do")
                        }

                        self.isCheckingRSSI = false
                    }
                } else {
                    NSLog("Bizzare, cannot get device info")
                }
            } else {
                if self.priorStatus == BPStatus.inRange {
                    self.priorStatus = BPStatus.outRange
                    
                }
                
                if (!self.screenIsLocked) {
                     NSLog("Device Out of range")
                    scriptObject = self.getOutRangeScript()
                }
               
            }
            
            DispatchQueue.main.async(execute: {
                self.setMenuIcon(self.priorStatus)
            })
            
            
//            return //do nothing
            
            if let _appleScript = scriptObject {
//                if self.isRunningScript {
//                    return
//                }
                self.isRunningScript = true
                //run
                var error : NSDictionary?
                let result = _appleScript.executeAndReturnError(&error)
                NSLog("execute result: \(result.debugDescription)")
                print("execute error: \(error?.description ?? "")")

                self.isRunningScript = false
            } else {
//                NSLog("Unecessary to launch script")
            }
//            
//            //if monitor is enabled -> re-schedule
//            let defaults = NSUserDefaults.standardUserDefaults()
//            
//            if defaults.boolForKey("enableMonitor") {
//                self.startMonitoring()
//            }
        })
    }
    
    func stopMonitoring() {
        if let _timer = timer {
            _timer.invalidate()
        }
    }
    
    
    func setMenuIcon(_ status: BPStatus) {
        switch (status) {
        case .outRange:
            statusItem?.image = NSImage(contentsOfFile: Bundle.main.path(forResource: "outRange", ofType: "png")!)
            statusItem?.alternateImage = NSImage(contentsOfFile: Bundle.main.path(forResource: "outRangeAlt", ofType: "png")!)
            break
        case .inRange:
            statusItem?.image = NSImage(contentsOfFile: Bundle.main.path(forResource: "inRange", ofType: "png")!)
            statusItem?.alternateImage = NSImage(contentsOfFile: Bundle.main.path(forResource: "inRangeAlt", ofType: "png")!)
            break
        }
    }
    
    //MARK: NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        
        stopMonitoring()
        startMonitoring()
    }
}

