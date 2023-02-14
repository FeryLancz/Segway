//
//  Segway.swift
//  Segway
//
//  Created by Fery Lancz on 13.04.15.
//  Copyright (c) 2015 Fery Lancz. All rights reserved.
//

import Foundation
import CoreBluetooth

class Segway: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    enum status: String {
        case Initial = "nicht Verbunden"
        case Searching = "Suchen"
        case Connecting = "Verbinden"
        case Ready = "Verbunden"
        case Disconnected = "Verbindung getrennt"
        case DidLostConnection = "Verbindung verloren"
        case PoweredOff = "Bluetooth deaktiviert"
        case Resetting = "Zurücksetzen"
        case Unauthorized = "keine Berechtigung"
        case Unknown = "Unbekannt"
        case Unsupported = "Bluetooth 4.0 nicht verfügbar"
    }
    var connectionStatus = status.Initial
    var connectToPeripheral = false
    var disconnectFromPeripheral = false
    var centralManager: CBCentralManager!
    var bluetoothPeripheral: CBPeripheral!
    var writeCharacteristic: CBCharacteristic!
    var readCharacteristic: CBCharacteristic!
    var commandByte: Byte!
    var pwm: Int = 0
    var angle: Float = 0
    
    let peripheralName = "Segway"
    let serviceUUID = CBUUID(string: "2220")
    let writeUUID = CBUUID(string: "2222")
    let readUUID = CBUUID(string: "2221")
    
    func setSpeed(forward: Float, steer: Float) {
        var floatArray = [forward, steer]
        let data = NSData(bytes: &floatArray, length: sizeof(Float) * 2)
        send(data)
    }
    
    func setFactors(proportional: Float, derivative: Float, pwmScale: Float) {
        var dataArray = [proportional, derivative, pwmScale]
        let data = NSData(bytes: &dataArray, length: sizeof(Float) * 3)
        send(data)
    }
    
    func sendByte(data: Byte) {
        var mutableByte = data
        let byteData = NSData(bytes: &mutableByte, length: sizeof(Byte))
        send(byteData)
    }
    
    func sendInt(data: Int16) {
        var mutableInt16 = data
        let byteData = NSData(bytes: &mutableInt16, length: 2)
        send(byteData)
    }
    
    func sendFloat(data: Float) {
        var mutabelFloat = data
        let floatData = NSData(bytes: &mutabelFloat, length: sizeof(Float))
        send(floatData)
    }
    
    func send(data: NSData) {
        if connectionStatus == .Ready {
            bluetoothPeripheral.writeValue(data, forCharacteristic: writeCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        }
    }
    
    func connect() {
        if connectionStatus != .Ready {
            connectToPeripheral = true
            connectionStatus = .Searching
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    func disconnect() {
        if connectionStatus == .Ready {
            centralManager.cancelPeripheralConnection(bluetoothPeripheral)
            disconnectFromPeripheral = true
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        if central.state == CBCentralManagerState.PoweredOn {
            if connectToPeripheral {
                connectToPeripheral = false
                central.scanForPeripheralsWithServices(nil, options: nil)
            }
        }
        else if central.state == CBCentralManagerState.PoweredOff {
            connectionStatus = .PoweredOff
        }
        else if central.state == CBCentralManagerState.Resetting {
            connectionStatus = .Resetting
        }
        else if central.state == CBCentralManagerState.Unauthorized {
            connectionStatus = .Unauthorized
        }
        else if central.state == CBCentralManagerState.Unknown {
            connectionStatus = .Unknown
        }
        else if central.state == CBCentralManagerState.Unsupported {
            connectionStatus = .Unsupported
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        let nameOfFoundDevice = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as? NSString
        if let name = nameOfFoundDevice {
            if name == peripheralName {
                connectionStatus = .Connecting
                centralManager.stopScan()
                bluetoothPeripheral = peripheral
                bluetoothPeripheral.delegate = self
                centralManager.connectPeripheral(bluetoothPeripheral, options: nil)
            }
        }
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        peripheral.discoverServices(nil)
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        for service in peripheral.services {
            let thisService = service as CBService
            if thisService.UUID == serviceUUID {
                peripheral.discoverCharacteristics(nil, forService: thisService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        for characteristic in service.characteristics {
            let thisCharacteristic = characteristic as CBCharacteristic
            if thisCharacteristic.UUID == writeUUID {
                writeCharacteristic = thisCharacteristic
            }
            if thisCharacteristic.UUID == readUUID {
                readCharacteristic = thisCharacteristic
                bluetoothPeripheral.setNotifyValue(true, forCharacteristic: thisCharacteristic)
            }
        }
        if writeCharacteristic != nil && readCharacteristic != nil {
            connectionStatus = .Ready
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if characteristic.UUID == readUUID {
            let dataBytes = characteristic.value
            let dataLength = dataBytes.length
            var dataArray = [Byte](count: dataLength, repeatedValue: 0)
            dataBytes.getBytes(&dataArray, length: sizeof(Float))
            if dataLength == 1 {
                commandByte = dataArray[0]
            }
            else if dataLength == 4 {
                if commandByte == 0x86 {
                    var dataInt: Int32 = 0
                    memcpy(&dataInt, dataArray, 4)
                    pwm = Int(dataInt)
                }
                else if commandByte == 0xBC {
                    var dataFloat: Float = 0
                    memcpy(&dataFloat, dataArray, 4)
                    angle = dataFloat
                }
            }
        }
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        writeCharacteristic = nil
        readCharacteristic = nil
        if disconnectFromPeripheral {
            disconnectFromPeripheral = false
            connectionStatus = .Disconnected
        }
        else {
            connectionStatus = .DidLostConnection
            if central.state == CBCentralManagerState.PoweredOn {
                central.scanForPeripheralsWithServices(nil, options: nil)
            }
            else if central.state == CBCentralManagerState.PoweredOff {
                connectionStatus = .PoweredOff
            }
            else if central.state == CBCentralManagerState.Resetting {
                connectionStatus = .Resetting
            }
            else if central.state == CBCentralManagerState.Unauthorized {
                connectionStatus = .Unauthorized
            }
            else if central.state == CBCentralManagerState.Unknown {
                connectionStatus = .Unknown
            }
            else if central.state == CBCentralManagerState.Unsupported {
                connectionStatus = .Unsupported
            }
            else {
                connectionStatus = .Unknown
            }
        }
    }
}


