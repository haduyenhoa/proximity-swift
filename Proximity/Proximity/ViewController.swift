//
//  ViewController.swift
//  Proximity
//
//  Created by Duyen Hoa Ha on 31/03/2015.
//  Copyright (c) 2015 HA Duyen Hoa. All rights reserved.
//

import Cocoa
import IOBluetoothUI
import AppKit
import Foundation

// Monadic bind for Optionals
infix operator >>= {associativity left}
func >>= <A,B> (m: A?, f: A -> B?) -> B? {
    if let x = m {return f(x)}
    return .None
}

extension Character {
    func utf8() -> UInt8 {
        let utf8 = String(self).utf8
        return utf8[utf8.startIndex]
    }
}



class ViewController: NSViewController {

    let CRYPT_KEY = "ThisIsMyCryptKey"
    
    @IBOutlet weak var cbShowPassword: NSButton!
    @IBOutlet weak var tfPassword: NSSecureTextField!
    @IBOutlet weak var tfUsername: NSTextField!
    @IBOutlet weak var cbEnableMonitoring: NSButton!
    @IBOutlet weak var cbRunOnStartup: NSButton!
    @IBOutlet weak var tfScheduleInterval: NSTextField!
    @IBOutlet weak var piCheckingConnectivity: NSProgressIndicator!
    @IBOutlet weak var btnCheckConnectivity: NSButton!
    @IBOutlet weak var lblDeviceName: NSTextField!
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        btnCheckConnectivity.enabled = false
        piCheckingConnectivity.hidden = true
        
        loadApplicationStates()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        //verify device status
        
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func loadApplicationStates() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let _appDelegate = NSApplication.sharedApplication().delegate as? AppDelegate
        
        if _appDelegate == nil {125
            NSLog("Got error while getting delegate")
            return
        }
       
        //Update device & status
        if let _deviceData = defaults.objectForKey("pairedDevice") as? NSData{
            _appDelegate!.device = NSKeyedUnarchiver.unarchiveObjectWithData(_deviceData) as? IOBluetoothDevice
            
            if let _bluetoothDevice = _appDelegate!.device {
                lblDeviceName.stringValue = "\(_bluetoothDevice.name)  \(_bluetoothDevice.addressString)"
                lblDeviceName.textColor = NSColor.blackColor()
                
                //enable check
                btnCheckConnectivity.enabled = true
            }
        }
        
        dispatch_async(dispatch_queue_create("com.haduyenhoa.service.bluetooth", nil), {
            //update status bar
            if _appDelegate!.isInRange() {
                _appDelegate!.priorStatus = .InRange
            } else {
                _appDelegate!.priorStatus = .OutRange
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                _appDelegate!.setMenuIcon(_appDelegate!.priorStatus)
            })
            
        })
        
        
        //timer interval
        var timerInterval = defaults.doubleForKey("timerInterval")
        if timerInterval <= 0 || timerInterval > 120 {
            timerInterval = 60 //reset timer interval
            //update NSuserdefault
            defaults.setDouble(timerInterval, forKey: "timerInterval")
        }
        
        _appDelegate?.timerInterval = timerInterval
        tfScheduleInterval.stringValue = "\(timerInterval)"
        
        //Enable
        let enableMonitoring = defaults.boolForKey("enableMonitor")
        if enableMonitoring {
            cbEnableMonitoring.state = NSOnState
            
            //start monitoring
            _appDelegate!.startMonitoring()
        } else {
            cbEnableMonitoring.state = NSOffState
            _appDelegate!.stopMonitoring()
        }
        
        //Run on start up
        let runOnStartup = defaults.boolForKey("runOnStartup")
        cbRunOnStartup.state = runOnStartup ? NSOnState : NSOffState
        
        //user name
        var username: String? = defaults.stringForKey("username") ?? ""
        var password : String? = defaults.stringForKey("password") ?? ""
        
        username = username.map(encryptKey(CRYPT_KEY)) ?? ""
        password = password.map(encryptKey(CRYPT_KEY)) ?? ""
//        let encryptedMessage = encryptKey(CRYPT_KEY)(message: username!)
        
        
        
        tfUsername.stringValue = username!
        tfPassword.stringValue = password!
        _appDelegate!.password = password ?? ""; //defaults.stringForKey("password") ?? ""
    }
    
    @IBAction func saveSettings(sender: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let _appDelegate = NSApplication.sharedApplication().delegate as? AppDelegate
        
        if _appDelegate == nil {
            NSLog("Got error while getting delegate")
            return
        }
        
        defaults.setDouble(tfScheduleInterval.doubleValue, forKey: "timerInterval")
        
        defaults.setBool(cbEnableMonitoring.state == NSOnState, forKey: "enableMonitor")
        defaults.setBool(cbRunOnStartup.state == NSOnState, forKey: "runOnStartup")
        
        var username : String?  = tfUsername.stringValue ?? ""
        var password : String? = tfPassword.stringValue ?? ""
        
        let encryptedUsername = encryptKey(CRYPT_KEY)(message: username!)
        let encryptedPassword = encryptKey(CRYPT_KEY)(message: password!)
        
        defaults.setObject(encryptedUsername, forKey: "username")
        defaults.setObject(encryptedPassword, forKey: "password")
        defaults.synchronize()
        
        _appDelegate!.password = tfPassword.stringValue ?? ""
        
        if cbEnableMonitoring.state == NSOnState {
            NSLog("Restart monitoring")
            _appDelegate!.stopMonitoring()
            _appDelegate!.startMonitoring()
        } else {
            NSLog("Stop monitoring")
            _appDelegate!.stopMonitoring()
        }
        
    }
    
    
    @IBAction func showPassword(sender: AnyObject) {
        let onState = (sender as NSButton).state == NSOnState
        
        if onState {
            //TODO: replace NSSecureTextField by NSTextField
        }
    }
    
    
    @IBAction func timerIntervalChanged(sender: AnyObject) {
    }

    @IBAction func enableMonitoringChanged(sender: AnyObject) {
    }
    
    @IBAction func changeDevice(sender: AnyObject) {
        let _appDelegate = NSApplication.sharedApplication().delegate as? AppDelegate
        
        if _appDelegate == nil {
            NSLog("Got error while getting delegate")
            return
        }
        
        let deviceSelector = IOBluetoothDeviceSelectorController.deviceSelector()

        deviceSelector.runModal()
        
        //get device
        var results = deviceSelector.getResults()
        if results == nil || results.count == 0 {
            NSLog("User has cancel or did not selecte any thing")
            return
        }
        
        if let _device = results[0] as? IOBluetoothDevice{
            //save to NSUSerdaults
            let defaults = NSUserDefaults.standardUserDefaults()
            let data = NSKeyedArchiver.archivedDataWithRootObject(_device)
            defaults.setObject(data, forKey: "pairedDevice")
            
            
             _appDelegate!.device = _device

            lblDeviceName.stringValue = "\(_device.name)  \(_device.addressString)"
            lblDeviceName.textColor = NSColor.blackColor()
            
            //enable check
            btnCheckConnectivity.enabled = true
        } else {
            if (_appDelegate!.device == nil) {
                lblDeviceName.textColor = NSColor.redColor()
                
            }
        }
        
    }

    @IBAction func checkConnectivity(sender: AnyObject) {
        
    dispatch_async(dispatch_queue_create("com.haduyenhoa.service.bluetooth", nil), {
        let _appDelegate = NSApplication.sharedApplication().delegate as? AppDelegate
        
        if _appDelegate == nil {
            NSLog("Got error while getting delegate")
            return
        }
        
        if _appDelegate!.device == nil {
            NSLog("There is no device available")
            return
        }
        
        //start animation
        dispatch_async(dispatch_get_main_queue(), {
            self.piCheckingConnectivity.hidden = false
            self.piCheckingConnectivity.startAnimation(nil)
        })
       
        
        if (_appDelegate!.isInRange()) {
            dispatch_async(dispatch_get_main_queue(), {
                self.piCheckingConnectivity.stopAnimation(nil)
                 NSLog("Connection to this bluetooth device is OK")
                _appDelegate!.setMenuIcon(BPStatus.InRange)
            })
            
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                self.piCheckingConnectivity.stopAnimation(nil)
                
                //show error
                NSLog("Got error while connecting to device")
                
                _appDelegate!.setMenuIcon(BPStatus.OutRange)
            })
            
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.piCheckingConnectivity.hidden = true
        })
        
        
        })
    }
    
    //MARK: cryptographie
    func encrypt(key:Character, c:Character) -> String? {
        let byte = [key.utf8() ^ c.utf8()]
        return String(bytes: byte, encoding: NSUTF8StringEncoding)
    }
    
    // Curried func for convenient use with map
    func encryptKey(key:String)(message:String) -> String? {
        return reduce(Zip2(key, message), Optional("")) { str, c in str >>= { s in self.encrypt(c).map {s + $0} }}
    }
}

