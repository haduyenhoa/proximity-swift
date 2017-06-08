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

//// Monadic bind for Optionals
//infix operator >>= {associativity left}
//func >>= <A,B> (m: A?, f: (A) -> B?) -> B? {
//    if let x = m {return f(x)}
//    return .none
//}

extension Character {
    func utf8() -> UInt8 {
        let utf8 = String(self).utf8
        return utf8[utf8.startIndex]
    }
}



class ViewController: NSViewController {

    let CRYPT_KEY = "ThisIsMyCryptKey" //change your cryptkey
    
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
        btnCheckConnectivity.isEnabled = false
        piCheckingConnectivity.isHidden = true
        
        loadApplicationStates()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        //TODO: verify device status
        
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func loadApplicationStates() {
        let defaults = UserDefaults.standard
        let _appDelegate = NSApplication.shared.delegate as? AppDelegate
        
        if _appDelegate == nil {
            NSLog("Got error while getting delegate")
            return
        }
       
        //Update device & status
        if let _deviceData = defaults.object(forKey: "pairedDevice") as? Data{
            _appDelegate!.device = NSKeyedUnarchiver.unarchiveObject(with: _deviceData) as? IOBluetoothDevice
            
            if let _bluetoothDevice = _appDelegate!.device {
                lblDeviceName.stringValue = "\(_bluetoothDevice.name)  \(_bluetoothDevice.addressString)"
                lblDeviceName.textColor = NSColor.black
                
                //enable check
                btnCheckConnectivity.isEnabled = true
            }
        }
        
        DispatchQueue(label: "com.haduyenhoa.service.bluetooth", attributes: []).async(execute: {
            //update status bar
            if _appDelegate!.isInRange() {
                _appDelegate!.priorStatus = .inRange
            } else {
                _appDelegate!.priorStatus = .outRange
            }
            
            DispatchQueue.main.async(execute: {
                _appDelegate!.setMenuIcon(_appDelegate!.priorStatus)
            })
            
        })
        
        
        //timer interval
        var timerInterval = defaults.double(forKey: "timerInterval")
        if timerInterval <= 0 || timerInterval > 120 {
            timerInterval = 60 //reset timer interval
            //update NSuserdefault
            defaults.set(timerInterval, forKey: "timerInterval")
        }
        
        _appDelegate?.timerInterval = timerInterval
        tfScheduleInterval.stringValue = "\(timerInterval)"
        
        //Enable
        let enableMonitoring = defaults.bool(forKey: "enableMonitor")
        if enableMonitoring {
            cbEnableMonitoring.state = NSControl.StateValue.onState
            
            //start monitoring
            _appDelegate!.startMonitoring()
        } else {
            cbEnableMonitoring.state = NSControl.StateValue.offState
            _appDelegate!.stopMonitoring()
        }
        
        //Run on start up
        let runOnStartup = defaults.bool(forKey: "runOnStartup")
        cbRunOnStartup.state = runOnStartup ? NSControl.StateValue.onState : NSControl.StateValue.offState
        
        //user name
        let username: String? = defaults.string(forKey: "username") ?? ""
        let password : String? = defaults.string(forKey: "password") ?? ""

        //TODO: crypt username + password
//        username = username.map(encryptKey(CRYPT_KEY, <#String#>)) ?? ""
//        password = password.map(encryptKey(CRYPT_KEY, <#String#>)) ?? ""
//        let encryptedMessage = encryptKey(CRYPT_KEY)(message: username!)
        

        
        
        tfUsername.stringValue = username!
        tfPassword.stringValue = password!
        _appDelegate!.username = username ?? "";
        _appDelegate!.password = password ?? ""; //defaults.stringForKey("password") ?? ""
    }
    
    @IBAction func saveSettings(_ sender: AnyObject) {
        let defaults = UserDefaults.standard
        let _appDelegate = NSApplication.shared.delegate as? AppDelegate
        
        if _appDelegate == nil {
            NSLog("Got error while getting delegate")
            return
        }
        
        defaults.set(tfScheduleInterval.doubleValue, forKey: "timerInterval")
        
        defaults.set(cbEnableMonitoring.state == NSControl.StateValue.onState, forKey: "enableMonitor")
        defaults.set(cbRunOnStartup.state == NSControl.StateValue.onState, forKey: "runOnStartup")
        
        let username : String?  = tfUsername.stringValue
        let password : String? = tfPassword.stringValue

        //TODO: encrypt username + password
//        let encryptedUsername = encryptKey(CRYPT_KEY, <#String#>)(username!)
//        let encryptedPassword = encryptKey(CRYPT_KEY, <#String#>)(password!)

        defaults.set(username, forKey: "username")
        defaults.set(password, forKey: "password")
        defaults.synchronize()
        
        _appDelegate!.username = tfUsername.stringValue
        _appDelegate!.password = tfPassword.stringValue 
        
        if cbEnableMonitoring.state == NSControl.StateValue.onState {
            NSLog("Restart monitoring")
            _appDelegate!.stopMonitoring()
            _appDelegate!.startMonitoring()
        } else {
            NSLog("Stop monitoring")
            _appDelegate!.stopMonitoring()
        }
        
    }
    
    
    @IBAction func showPassword(_ sender: AnyObject) {
        let onState = (sender as! NSButton).state == NSControl.StateValue.onState
        
        if onState {
            //TODO: replace NSSecureTextField by NSTextField
        }
    }
    
    
    @IBAction func timerIntervalChanged(_ sender: AnyObject) {
    }

    @IBAction func enableMonitoringChanged(_ sender: AnyObject) {
    }
    
    @IBAction func changeDevice(_ sender: AnyObject) {
        let _appDelegate = NSApplication.shared.delegate as? AppDelegate
        
        if _appDelegate == nil {
            NSLog("Got error while getting delegate")
            return
        }
        
        let deviceSelector = IOBluetoothDeviceSelectorController.deviceSelector()

        deviceSelector?.runModal()
        
        //get device
        var results = deviceSelector?.getResults()
        if results == nil || results?.count == 0 {
            NSLog("User has cancel or did not selecte any thing")
            return
        }
        
        if let _device = results?[0] as? IOBluetoothDevice{
            //save to NSUSerdaults
            let defaults = UserDefaults.standard
            let data = NSKeyedArchiver.archivedData(withRootObject: _device)
            defaults.set(data, forKey: "pairedDevice")
            
            
             _appDelegate!.device = _device

            lblDeviceName.stringValue = "\(_device.name)  \(_device.addressString)"
            lblDeviceName.textColor = NSColor.black
            
            //enable check
            btnCheckConnectivity.isEnabled = true
        } else {
            if (_appDelegate!.device == nil) {
                lblDeviceName.textColor = NSColor.red
                
            }
        }
        
    }

    @IBAction func checkConnectivity(_ sender: AnyObject) {
        
    DispatchQueue(label: "com.haduyenhoa.service.bluetooth", attributes: []).async(execute: {
        let _appDelegate = NSApplication.shared.delegate as? AppDelegate
        
        if _appDelegate == nil {
            NSLog("Got error while getting delegate")
            return
        }
        
        if _appDelegate!.device == nil {
            NSLog("There is no device available")
            return
        }
        
        //start animation
        DispatchQueue.main.async(execute: {
            self.piCheckingConnectivity.isHidden = false
            self.piCheckingConnectivity.startAnimation(nil)
        })
       
        
        if (_appDelegate!.isInRange()) {
            DispatchQueue.main.async(execute: {
                self.piCheckingConnectivity.stopAnimation(nil)
                 NSLog("Connection to this bluetooth device is OK")
                _appDelegate!.setMenuIcon(BPStatus.inRange)
            })
            
        } else {
            DispatchQueue.main.async(execute: {
                self.piCheckingConnectivity.stopAnimation(nil)
                
                //show error
                NSLog("Got error while connecting to device")
                
                _appDelegate!.setMenuIcon(BPStatus.outRange)
            })
            
        }
        DispatchQueue.main.async(execute: {
            self.piCheckingConnectivity.isHidden = true
        })
        
        
        })
    }

    /*
    //MARK: cryptographie
    func encrypt(_ key:Character, c:Character) -> String? {
        let byte = [key.utf8() ^ c.utf8()]
        return String(bytes: byte, encoding: String.Encoding.utf8)
    }
    
    // Curried func for convenient use with map
    func encryptKey(_ key:String, _ message:String) -> String? {
        return reduce(Zip2(key, message), Optional("")) { str, c in str >>= { s in self.encrypt(c).map {s + $0} }}
    }
   */
}

