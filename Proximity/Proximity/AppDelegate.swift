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
    case InRange
    case OutRange
}

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, CBPeripheralManagerDelegate {
    var bluetoothManager : CBPeripheralManager?
    var device : IOBluetoothDevice?
    var password :String = ""
    var statusItem : NSStatusItem?
    var timer : NSTimer?
    var timerInterval : NSTimeInterval = 60
    var screenIsLocked = false
    
    var priorStatus : BPStatus =  BPStatus.OutRange
    var isRunningScript = false
    var isCheckingRSSI = false
    
    
    var enableMonitoring = false
    
    @IBOutlet weak var cbShowPassword: NSWindow!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        //load password to create script
        let defaults = NSUserDefaults.standardUserDefaults()
        password = defaults.stringForKey("password") ?? ""
        
       (NSApplication.sharedApplication().windows.first as NSWindow).delegate = self
        
        let center = NSDistributedNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "screenLocked", name: "com.apple.screenIsLocked", object: nil)
        center.addObserver(self, selector: "screenUnlocked", name: "com.apple.screenIsUnlocked", object: nil)
        
        createMenuBar()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    //MARK: Helps
    func isInRange() -> Bool{
        return device != nil && device?.remoteNameRequest(nil) == kIOReturnSuccess
    }
    
    func screenLocked() {
        screenIsLocked = true
        NSLog("Screen is locked")
    }
    
    func screenUnlocked() {
        screenIsLocked = false
        NSLog("Screen is unlocked")
    }
    
    
    func createMenuBar() {
        //create Menu
        let menu = NSMenu()
        
        //button preferences
        menu.addItemWithTitle("Preferences", action: "showPreferences", keyEquivalent: "")
        
        //btn quit
        menu.addItemWithTitle("Quit", action: "terminate", keyEquivalent: "")
        
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        
        statusItem?.highlightMode = true
        statusItem?.menu = menu
        
        setMenuIcon(BPStatus.OutRange)
    }
    
    func getInRangeScript() -> NSAppleScript {
        //wake up
        var assertionID = IOPMAssertionID()
        let str : CFString = ""
        let result =  IOPMAssertionDeclareUserActivity(str, kIOPMUserActiveLocal, &assertionID)
        
        let scriptObject = NSAppleScript(source:
            "on run\n"
//            + "tell application \"System Events\"\n"
//            + "tell process \"Finder\"\n"
//            + "key space\n"
//            + "end tell\n"
//            + "end tell\n"
            + "tell application \"/System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app\" to quit\n"
//            + "tell application \"System Events\" to key code 53\n"

            + "delay 4.0\n"
            + "tell application \"System Events\" to keystroke \"" + (password) + "\"\n"
            + "delay 0.5\n"
            + "tell application \"System Events\" to keystroke return\n"
            + "end run\n"
        )
        
        return scriptObject!
    }
    
    func getOutRangeScript() -> NSAppleScript {
        let scriptObject = NSAppleScript(source:
            "on run\n"
                + "activate application \"/System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app\"\n"
                + "end run\n"
        )
        return scriptObject!
    }
    
    //MARK: Menu action
    func showPreferences() {
        NSApplication.sharedApplication().windows.first?.makeKeyAndOrderFront(self)
        NSApplication.sharedApplication().windows.first?.orderFrontRegardless()
        NSApplication.sharedApplication().windows.first?.center()
    }
    
    func terminate() {
        NSApplication.sharedApplication().terminate(self)
    }
    
    func startMonitoring() {
        if screenIsLocked {
            timer = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: "handleTimer", userInfo: nil, repeats: true)
        } else {
            timer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "handleTimer", userInfo: nil, repeats: true)
        }
        
    }
    
    func handleTimer() {
        var scriptObject : NSAppleScript?
        
        dispatch_async(dispatch_queue_create("com.haduyenhoa.service.bluetooth", nil), {
            if self.isInRange() {
                if self.priorStatus == BPStatus.OutRange {
                    self.priorStatus = BPStatus.InRange
                }
                
                if (self.screenIsLocked
                    ) {
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
                                rssi = self.device!.RSSI()
                                self.device?.closeConnection()

                            }
                            
                            NSLog("device rssi \(rssi))")
                            if (rssi < -3 || rssi > 20) {
                                NSLog("Bluetooth is not near by my Mac. Do nothing")
                                self.isCheckingRSSI = false
                                
                            } else {
                                NSLog("Device in Range")
                                scriptObject = self.getInRangeScript()
                                self.isCheckingRSSI = false
                            }
                        }
                    } else {
                        NSLog("Bizzare, cannot get device info")
                    }
                }
            } else {
                if self.priorStatus == BPStatus.InRange {
                    self.priorStatus = BPStatus.OutRange
                    
                }
                
                if (!self.screenIsLocked) {
                     NSLog("Device Out of range")
                    scriptObject = self.getOutRangeScript()
                }
               
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.setMenuIcon(self.priorStatus)
            })
            
            
//            return //do nothing
            
            if let _appleScript = scriptObject {
                if self.isRunningScript {
                    return
                }
                self.isRunningScript = true
                //run
                var error : NSDictionary?
                let result = _appleScript.executeAndReturnError(&error)
                NSLog("execute result: \(result?.debugDescription)")
                NSLog("execute error: \(error)")
                self.isRunningScript = false
            } else {
                NSLog("Unecessary to launch script")
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
    
    
    func setMenuIcon(status: BPStatus) {
        switch (status) {
        case .OutRange:
            statusItem?.image = NSImage(contentsOfFile: NSBundle.mainBundle().pathForResource("outRange", ofType: "png")!)
            statusItem?.alternateImage = NSImage(contentsOfFile: NSBundle.mainBundle().pathForResource("outRangeAlt", ofType: "png")!)
            break
        case .InRange:
            statusItem?.image = NSImage(contentsOfFile: NSBundle.mainBundle().pathForResource("inRange", ofType: "png")!)
            statusItem?.alternateImage = NSImage(contentsOfFile: NSBundle.mainBundle().pathForResource("inRangeAlt", ofType: "png")!)
            break
        }
    }
    
    //MARK: NSWindowDelegate
    func windowWillClose(notification: NSNotification) {
        
        stopMonitoring()
        startMonitoring()
    }
    
    //MARK: CBPeripheralManager
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        
    }
    
}

