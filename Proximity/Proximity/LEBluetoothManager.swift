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
    func servicesUpdated(_ peripheral : CBPeripheral!)
}

//This class is for another purpose, not for autolock
class LEBluetoothManager : NSObject {
    private static let share = LEBluetoothManager()

    var bluetoothManager : CBCentralManager?
    var delegate : LEBluetoothManagerDelegate?
    var currentCBPeripheral : CBPeripheral?
    
    
    class func SharedInstance() -> LEBluetoothManager {
        return share
    }
    
    func enableLE() {
//        self.bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }
}


extension LEBluetoothManager : CBCentralManagerDelegate {
    @available(OSX 10.7, *)
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(OSX 10.13, *) {
            switch central.state {
            case .poweredOn :
                self.bluetoothManager?.scanForPeripherals(withServices: nil , options: nil )
                break
            default:
                print("central state :\(central.state)")
                break
            }
        } else {
            // Fallback on earlier versions
            switch central.state.rawValue {
            case 5 :
                self.bluetoothManager?.scanForPeripherals(withServices: nil , options: nil )
                break
            default:
                print("central state :\(central.state)")
                break
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        print("RSI: \(RSSI.doubleValue)")

        NSLog("Discovered: \(peripheral)")
        NSLog("ALl keys : \(advertisementData.keys)")
        NSLog("values: \(advertisementData.values)")


        let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        print("data: \(String(describing: data))")

        currentCBPeripheral = peripheral
        currentCBPeripheral?.delegate = self

        let isConnectable:Bool = advertisementData["kCBAdvDataIsConnectable"] as! Bool

        if (isConnectable) {
            self.bluetoothManager?.connect(currentCBPeripheral!, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        currentCBPeripheral = peripheral
        currentCBPeripheral?.delegate = self
        currentCBPeripheral?.discoverServices(nil)
    }
}

extension LEBluetoothManager : CBPeripheralDelegate {
    //MARK: Peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in (peripheral.services ?? []) {
            NSLog("service : \(service.description)")
            currentCBPeripheral?.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        NSLog("service : \(service.description)")
        NSLog("characters : \(String(describing: service.characteristics))")

        currentCBPeripheral?.readValue(for: (service.characteristics?.first)!)
    }
}
