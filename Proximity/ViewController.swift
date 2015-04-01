//
//  ViewController.swift
//  Proximity
//
//  Created by Duyen Hoa Ha on 30/03/2015.
//  Copyright (c) 2015 Duyen Hoa Ha. All rights reserved.
//

import Cocoa
import CoreBluetooth
import IOBluetoothUI

class ViewController: NSViewController {

    private var device : IOBluetoothDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


    @IBAction func changeDevice(sender: AnyObject) {
        var deviceSelector = IOBluetoothDeviceSelectorController.deviceSelector()
        deviceSelector.runModal()
        
        var result = deviceSelector.getResults()
        
        if result.count == 0 {
            return
        } else {
            device = result.first as? IOBluetoothDevice
        }
        
            
        
    }
}

