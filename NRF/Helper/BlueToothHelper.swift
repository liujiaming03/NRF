//
//  BlueToothHelper.swift
//  StopHere
//
//  Created by yuszha on 2017/7/20.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import UIKit
import CoreBluetooth

enum PeripheralRecivedType : String {
    case hex = "Hex"
    case ascii = "ASCII"
    case number = "Number"
}

@objc protocol BlueToothHelperDelegate {
    
    @objc optional func centralManagerDidUpdateState(_ central: CBCentralManager)
    @objc optional func discoverPeripheral(_ helper: BlueToothHelper , peripheral: CBPeripheral)
    @objc optional func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber)
    @objc optional func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral)
    @objc optional func peripheralDidUpdateName(_ peripheral: CBPeripheral)
    
    @objc optional func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService)
    
    @objc optional func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, value: String)
    
    @objc optional func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    
    @objc optional func centralManagerDidConnect(_ peripheral: CBPeripheral)
    
    @objc optional func centralManagerDidDisconnectPeripheral(_ peripheral: CBPeripheral)
    @objc optional func centralManagerDidFailToConnect(_ peripheral: CBPeripheral)
    
    @objc optional func peripheral(_ peripheral: CBPeripheral, didUpdateElectricity electricity: Int, state: String)
    
}

let BlueToothHelperDefaultRecivedType   = "BlueToothHelperDefaultRecivedType"
let BlueToothHelperRCharacteristicUUIDString = "BlueToothHelperRCharacteristicUUIDString"
let BlueToothHelperCurrentLockIndex = "BlueToothHelperCurrentLockIndex"
let BlueToothHelperShowPassword = "BlueToothHelperShowPassword"

class BlueToothHelper: NSObject {
    
    static let shared = BlueToothHelper()
    
    var peripherals = [CBPeripheral]()
    var centralManager : CBCentralManager!
    
    var delegates = [BlueToothHelperDelegate]()
    
    var nameMap = Dictionary<String, String>()
    
    func addDelegate(_ delegate: BlueToothHelperDelegate) {
        self.delegates.append(delegate)
    }
    
    func removeDelegate(_ delegate: BlueToothHelperDelegate) {

        for i in 0..<self.delegates.count {
            
            if delegate === delegates[i] {
                delegates.remove(at: i)
                break
            }
        }
    }
    
    func reDiscoverPeripherals() {
        for peripheral in peripherals {
            if peripheral.state == .connected {
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
        peripherals.removeAll()
        centralManager.stopScan()
        
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])

    }
    
    func discoverPeripherals() {
        if centralManager == nil {
            centralManager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main)
        }
        reDiscoverPeripherals()
    }
    
    func stopDiscoverPeripherals() {
        centralManager.stopScan()
    }
    
    func connect(_ peripheral : CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }
    
    func disConnect(_ peripheral : CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    var defaultRecivedType : PeripheralRecivedType {
        get {
            return ((UserDefaults.standard.value(forKey: BlueToothHelperDefaultRecivedType) as? String).map { PeripheralRecivedType(rawValue: $0) ?? .ascii }) ?? .ascii
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: BlueToothHelperDefaultRecivedType)
        }
    }
    
    var rCharacteristicUUIDString : String? {
        get {
            return UserDefaults.standard.value(forKey: BlueToothHelperRCharacteristicUUIDString) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: BlueToothHelperRCharacteristicUUIDString)
        }
    }
    
    var currentIndex : Int {
        get {
            return UserDefaults.standard.value(forKey: BlueToothHelperCurrentLockIndex) as? Int ?? 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: BlueToothHelperCurrentLockIndex)
        }
    }
    
    var showPassword : Bool {
        get {
            return UserDefaults.standard.value(forKey: BlueToothHelperShowPassword) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: BlueToothHelperShowPassword)
        }
    }
    
    func propertiesString(properties: CBCharacteristicProperties) -> (String)!{
        var propertiesReturn : String = ""
        
        if (properties.rawValue & CBCharacteristicProperties.broadcast.rawValue) != 0 {
            propertiesReturn += "可广播|"
        }
        if (properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            propertiesReturn += "可读|"
        }
        if (properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 {
            propertiesReturn += "可写-没有响应|"
        }
        if (properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0 {
            propertiesReturn += "可写|"
        }
        if (properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0 {
            propertiesReturn += "可通知|"
        }
        if (properties.rawValue & CBCharacteristicProperties.indicate.rawValue) != 0 {
            propertiesReturn += "声明|"
        }
        if (properties.rawValue & CBCharacteristicProperties.authenticatedSignedWrites.rawValue) != 0 {
            propertiesReturn += "通过验证的|"
        }
        if (properties.rawValue & CBCharacteristicProperties.extendedProperties.rawValue) != 0 {
            propertiesReturn += "拓展|"
        }
        if (properties.rawValue & CBCharacteristicProperties.notifyEncryptionRequired.rawValue) != 0 {
            propertiesReturn += "需要加密的通知|"
        }
        if (properties.rawValue & CBCharacteristicProperties.indicateEncryptionRequired.rawValue) != 0 {
            propertiesReturn += "需要加密的申明|"
        }
        return propertiesReturn
    }
    
    func resetCenterManager() {
        self.centralManager.delegate = self
        for peripheral in peripherals {
            peripheral.delegate = self
        }
        self.reDiscoverPeripherals()
    }
}

extension BlueToothHelper : CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
        else {
            
        }
    }
    
    
    /*!
     *  @method centralManager:willRestoreState:
     *
     *  @param central      The central manager providing this information.
     *  @param dict			A dictionary containing information about <i>central</i> that was preserved by the system at the time the app was terminated.
     *
     *  @discussion			For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
     *						the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
     *						Bluetooth system.
     *
     *  @seealso            CBCentralManagerRestoredStatePeripheralsKey;
     *  @seealso            CBCentralManagerRestoredStateScanServicesKey;
     *  @seealso            CBCentralManagerRestoredStateScanOptionsKey;
     *
     */
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        
    }
    
    
    /*!
     *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
     *
     *  @param central              The central manager providing this update.
     *  @param peripheral           A <code>CBPeripheral</code> object.
     *  @param advertisementData    A dictionary containing any advertisement and scan response data.
     *  @param RSSI                 The current RSSI of <i>peripheral</i>, in dBm. A value of <code>127</code> is reserved and indicates the RSSI
     *								was not available.
     *
     *  @discussion                 This method is invoked while scanning, upon the discovery of <i>peripheral</i> by <i>central</i>. A discovered peripheral must
     *                              be retained in order to use it; otherwise, it is assumed to not be of interest and will be cleaned up by the central manager. For
     *                              a list of <i>advertisementData</i> keys, see {@link CBAdvertisementDataLocalNameKey} and other similar constants.
     *
     *  @seealso                    CBAdvertisementData.h
     *
     */
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        nameMap[peripheral.identifier.uuidString] = (advertisementData["kCBAdvDataLocalName"] as? String) ?? peripheral.name ?? ""
        
        
        if peripherals.contains(peripheral) {
            for delegate in delegates {
                delegate.peripheral?(peripheral, didReadRSSI: RSSI)
                delegate.peripheralDidUpdateName?(peripheral)
            }
        }
        else {
            peripherals.append(peripheral)
            
            for delegate in delegates {
                delegate.discoverPeripheral?(self, peripheral: peripheral)
            }
            
        }
    }
    
    
    /*!
     *  @method centralManager:didConnectPeripheral:
     *
     *  @param central      The central manager providing this information.
     *  @param peripheral   The <code>CBPeripheral</code> that has connected.
     *
     *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has succeeded.
     *
     */
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        peripheral.readRSSI()
        for delegate in delegates {
            delegate.centralManagerDidConnect?(peripheral)
        }
    }
    
    
    /*!
     *  @method centralManager:didFailToConnectPeripheral:error:
     *
     *  @param central      The central manager providing this information.
     *  @param peripheral   The <code>CBPeripheral</code> that has failed to connect.
     *  @param error        The cause of the failure.
     *
     *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has failed to complete. As connection attempts do not
     *                      timeout, the failure of a connection is atypical and usually indicative of a transient issue.
     *
     */
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        for delegate in delegates {
            delegate.centralManagerDidFailToConnect?(peripheral)
        }
    }
    
    
    /*!
     *  @method centralManager:didDisconnectPeripheral:error:
     *
     *  @param central      The central manager providing this information.
     *  @param peripheral   The <code>CBPeripheral</code> that has disconnected.
     *  @param error        If an error occurred, the cause of the failure.
     *
     *  @discussion         This method is invoked upon the disconnection of a peripheral that was connected by {@link connectPeripheral:options:}. If the disconnection
     *                      was not initiated by {@link cancelPeripheralConnection}, the cause will be detailed in the <i>error</i> parameter. Once this method has been
     *                      called, no more methods will be invoked on <i>peripheral</i>'s <code>CBPeripheralDelegate</code>.
     *
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        for delegate in self.delegates {
            delegate.centralManagerDidDisconnectPeripheral?(peripheral)
        }
    }
}

extension BlueToothHelper : CBPeripheralDelegate {
    /*!
     *  @method peripheralDidUpdateName:
     *
     *  @param peripheral	The peripheral providing this update.
     *
     *  @discussion			This method is invoked when the @link name @/link of <i>peripheral</i> changes.
     */
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        if peripherals.contains(peripheral) {

            
        }
        for delegate in delegates {
            delegate.peripheralDidUpdateName?(peripheral)
        }

    }
    
    
    /*!
     *  @method peripheral:didModifyServices:
     *
     *  @param peripheral			The peripheral providing this update.
     *  @param invalidatedServices	The services that have been invalidated
     *
     *  @discussion			This method is invoked when the @link services @/link of <i>peripheral</i> have been changed.
     *						At this point, the designated <code>CBService</code> objects have been invalidated.
     *						Services can be re-discovered via @link discoverServices: @/link.
     */
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {}
    
    
    /*!
     *  @method peripheralDidUpdateRSSI:error:
     *
     *  @param peripheral	The peripheral providing this update.
     *	@param error		If an error occurred, the cause of the failure.
     *
     *  @discussion			This method returns the result of a @link readRSSI: @/link call.
     *
     *  @deprecated			Use {@link peripheral:didReadRSSI:error:} instead.
     */
    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        for delegate in delegates {
            delegate.peripheralDidUpdateRSSI?(peripheral)
        }
    }
    
    
    /*!
     *  @method peripheral:didReadRSSI:error:
     *
     *  @param peripheral	The peripheral providing this update.
     *  @param RSSI			The current RSSI of the link.
     *  @param error		If an error occurred, the cause of the failure.
     *
     *  @discussion			This method returns the result of a @link readRSSI: @/link call.
     */
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        for delegate in delegates {
            delegate.peripheral?(peripheral, didReadRSSI: RSSI)
        }
    }
    
    
    /*!
     *  @method peripheral:didDiscoverServices:
     *
     *  @param peripheral	The peripheral providing this information.
     *	@param error		If an error occurred, the cause of the failure.
     *
     *  @discussion			This method returns the result of a @link discoverServices: @/link call. If the service(s) were read successfully, they can be retrieved via
     *						<i>peripheral</i>'s @link services @/link property.
     *
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let services = peripheral.services {
            for service in services  {
//                print(service.uuid.uuidString, peripheral.identifier.uuidString)
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    
    /*!
     *  @method peripheral:didDiscoverIncludedServicesForService:error:
     *
     *  @param peripheral	The peripheral providing this information.
     *  @param service		The <code>CBService</code> object containing the included services.
     *	@param error		If an error occurred, the cause of the failure.
     *
     *  @discussion			This method returns the result of a @link discoverIncludedServices:forService: @/link call. If the included service(s) were read successfully,
     *						they can be retrieved via <i>service</i>'s <code>includedServices</code> property.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        
    }
    
    
    /*!
     *  @method peripheral:didDiscoverCharacteristicsForService:error:
     *
     *  @param peripheral	The peripheral providing this information.
     *  @param service		The <code>CBService</code> object containing the characteristic(s).
     *	@param error		If an error occurred, the cause of the failure.
     *
     *  @discussion			This method returns the result of a @link discoverCharacteristics:forService: @/link call. If the characteristic(s) were read successfully,
     *						they can be retrieved via <i>service</i>'s <code>characteristics</code> property.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for delegate in delegates {

            delegate.peripheral?(peripheral, didDiscoverCharacteristicsFor: service)
        }
    }
    
    
    /*!
     *  @method peripheral:didUpdateValueForCharacteristic:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param characteristic	A <code>CBCharacteristic</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let data = characteristic.value else {
            return
        }
        
        var result = ""
        
        var hexValue = ""
        
        for i in 0..<data.count {
            
            let value = Int(data[i])
            
            if defaultRecivedType == .hex {
                result = result + String.init(format: "%0X", value)
            }
            else if defaultRecivedType == .number {
                
                result = result + String(value)
            }
            else {
                let character = Character(UnicodeScalar(value)!)
                result = result + String.init(character)
            }
            
            hexValue = hexValue + String.init(format: "%0X", value)
        }
        
        for delegate in delegates {
            delegate.peripheral?(peripheral, didUpdateValueFor: characteristic, value: result)
        }
        
        
        if characteristic.uuid.uuidString == "FFF4" && hexValue.count == 2 , let eleAndState = Int(hexValue)  {
            
            let ele = (eleAndState / 10) * 10
            let stateIndetifier = eleAndState % 10
            
            var state = "未知"
            switch stateIndetifier {
            case 4:
                state = "0"
            case 5:
                state = "90"
            case 6:
                state = "0-90"
            default :
                state = "未知"
                break
            }
         
            for delegate in delegates {
                delegate.peripheral?(peripheral, didUpdateElectricity : ele, state: state)
            }
            
            
        }
    }
    
    
    /*!
     *  @method peripheral:didWriteValueForCharacteristic:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param characteristic	A <code>CBCharacteristic</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
     */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        for delegate in delegates {
            delegate.peripheral?(peripheral, didWriteValueFor: characteristic, error: error)
        }
    }
    
    
    /*!
     *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param characteristic	A <code>CBCharacteristic</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        
    }
    
    
    /*!
     *  @method peripheral:didDiscoverDescriptorsForCharacteristic:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param characteristic	A <code>CBCharacteristic</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method returns the result of a @link discoverDescriptorsForCharacteristic: @/link call. If the descriptors were read successfully,
     *							they can be retrieved via <i>characteristic</i>'s <code>descriptors</code> property.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?){
        
    }
    
    
    /*!
     *  @method peripheral:didUpdateValueForDescriptor:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param descriptor		A <code>CBDescriptor</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method returns the result of a @link readValueForDescriptor: @/link call.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        
    }
    
    
    /*!
     *  @method peripheral:didWriteValueForDescriptor:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param descriptor		A <code>CBDescriptor</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method returns the result of a @link writeValue:forDescriptor: @/link call.
     */
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        
    }
}


extension BlueToothHelper {


    func dataFromString(_ str: String) -> Data {
        return str.data(using: .utf8) ?? Data()
    }

    func stringFromData(_ data: Data?) -> String {
        
        if data == nil { return "" }
        
        
        return String.init(data: data!, encoding: .utf8) ?? ""
    }
}
