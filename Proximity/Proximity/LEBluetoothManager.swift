//
//  LEBluetoothManager.swift
//  testbeacon
//
//  Created by Duyen Hoa Ha on 27/03/2015.
//  Copyright (c) 2015 HA Duyen Hoa. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol LEBluetoothManagerDelegate {
    func peripheralsUpdated()
    func servicesUpdated(peripheral : CBPeripheral!)
}

class LEBluetoothManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var bluetoothManager : CBCentralManager?
    var delegate : LEBluetoothManagerDelegate?
    var currentCBPeripheral : CBPeripheral?
    
    
    class func SharedInstance() -> LEBluetoothManager {
        struct Static {
            static var instance: LEBluetoothManager? = nil
            static var onceToken: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.onceToken, {
            Static.instance = LEBluetoothManager()
        })
        
        return Static.instance!
    }
    
    func enableLE() {
//        self.bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    //MARK: Core Bluetooth
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        NSLog("\(__FUNCTION__)")
        
        
    }
    
    //MARK: central update
    func centralManagerDidUpdateState(central: CBCentralManager!) {
//        NSLog("\(__FUNCTION__) New state: \(central.state)")
        
        switch (central.state)
        {
        case CBCentralManagerState.Unsupported:
                NSLog("State: Unsupported")
            break
            
        case CBCentralManagerState.Unauthorized:
                NSLog("State: Unauthorized")
            break
            
        case CBCentralManagerState.PoweredOff:
                NSLog("State: Powered Off")
            break
            
        case CBCentralManagerState.PoweredOn:
                NSLog("State: Powered On")
                self.bluetoothManager?.scanForPeripheralsWithServices(nil , options: nil )
            break
            
        case CBCentralManagerState.Unknown:
                NSLog("State: Unknown")
            break
            
        default:
            
            break
        }
    }
    
    func centralManager(central: CBCentralManager!, didRetrievePeripherals peripherals: [AnyObject]!) {
        NSLog("\(__FUNCTION__)")
        for perif in peripherals as [CBPeripheral] {
            NSLog("Perif: \(perif.identifier.UUIDString)")
            
            for service in perif.services as [CBService] {
                NSLog("service : \(service.description)")
            }
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
       
        if (peripheral.name == nil || peripheral.name.compare("iPod touch de Mag241", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) == NSComparisonResult.OrderedSame) {
             NSLog("Discovered: \(peripheral)")
            NSLog("ALl keys : \(advertisementData.keys.array)")
            NSLog("values: \(advertisementData.values.array)")
           
            
            let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
            
//            NSData *data = (NSData *)[advertisementDataDictionary objectForKey:CBAdvertisementDataManufacturerDataKey];
            
            currentCBPeripheral = peripheral
            currentCBPeripheral?.delegate = self
            
            let isConnectable:Bool = advertisementData["kCBAdvDataIsConnectable"] as Bool
            
            if (isConnectable) {
                self.bluetoothManager?.connectPeripheral(currentCBPeripheral, options: nil)
            }
        }
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("Perif: \(peripheral.identifier.UUIDString)")
        
        currentCBPeripheral = peripheral
        currentCBPeripheral?.delegate = self
        currentCBPeripheral?.discoverServices(nil)
        
        
    }
    
    //MARK: Peripheral
    func peripheral(peripheral: CBPeripheral!, didDiscoverIncludedServicesForService service: CBService!, error: NSError!) {
        NSLog("service : \(service.description)")
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        for service in peripheral.services as [CBService] {
            NSLog("service : \(service.description)")
            currentCBPeripheral?.discoverCharacteristics(nil, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        NSLog("peripheral : \(peripheral.description)")
        NSLog("characters : \(characteristic)")
        
        
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        NSLog("service : \(service.description)")
        NSLog("characters : \(service.characteristics)")
        
        currentCBPeripheral?.readValueForCharacteristic(service.characteristics.first as CBCharacteristic)
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {

         NSLog("descriptors : \(characteristic.properties)")
        
        
        if let descriptors = characteristic.descriptors {
             NSLog("descriptors : \(descriptors)")
        }
        
        NSLog("characteristic value : \(characteristic.value())")
    }
}