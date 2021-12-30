//
//  PeripheralSettingViewController.swift
//  StopHere
//
//  Created by yuszha on 2017/7/20.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import UIKit
import CoreBluetooth
import MessageUI
import iOSDFULibrary


let zipName = UserModel.shared.fileModel.name

class PeripheralSettingViewController: UIViewController {
    
    @IBOutlet var custemRightView: UIView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var uploadStatus: UILabel!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet var otherButtons: [UIButton]!
    @IBOutlet weak var fileStatusButton: UIButton!
    
    
//    var fileModel : DownloadFileModel! {
//        didSet {
//            fileStatusButton.setTitle(fileModel.name, for: .normal)
//            if let localPath = fileModel.localPath {
//                selectedFirmware = DFUFirmware(urlToZipFile: URL.init(fileURLWithPath: localPath))
//            }
//            
//        }
//    }

    var peripheral : CBPeripheral!
    
    let characteristicUUIDString = "FFF6"
    let serviceStrList = ["FFF1", "FFF2", "FFF3", "FFF4", "FFF5", "FFF6"]
    
    var characteristics = [CBCharacteristic]()
    var characteristic : CBCharacteristic?
    
    var dfuController      : DFUServiceController?
    var selectedFirmware   : DFUFirmware?
    //是否正在写入文件
    var isImportingFile = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if peripheral.state == .connected {
            refreshAction(refreshButton)
        }
        BlueToothHelper.shared.addDelegate(self)
        
        title = "OTA"
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: custemRightView)
        navigationItem.leftBarButtonItems = [UIBarButtonItem.init(image: UIImage.init(named: "back"), style: .plain, target: self, action: #selector(backAction)), UIBarButtonItem.init(title: BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] ?? "", style: .plain, target: nil, action: nil)]
        
        if peripheral.state == .connected {
            activityIndicatorView.stopAnimating()
            refreshButton.setTitle("已连接", for: UIControlState())
        }
        else {
            activityIndicatorView.startAnimating()
            refreshButton.setTitle("未连接", for: UIControlState())
        }
        if let localPath = Bundle.main.path(forResource: zipName, ofType: ".zip")  {
            selectedFirmware = DFUFirmware(urlToZipFile: URL.init(fileURLWithPath: localPath))
        }
        
        fileStatusButton.setTitle(zipName, for: .normal)
        
        print(peripheral.name)
        print(peripheral.identifier)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    @IBAction func refreshAction(_ sender: UIButton) {
        
        if self.peripheral.state == .disconnected {
            BlueToothHelper.shared.connect(peripheral)
        }
            
        else if self.peripheral.state == .connected {
            BlueToothHelper.shared.disConnect(peripheral)
        }
    } 
    
    @objc func backAction() {
        
        // 是否正在写入文件
        if self.isImportingFile {
            return
        }
        
        BlueToothHelper.shared.resetCenterManager()
        
        BlueToothHelper.shared.removeDelegate(self)
        BlueToothHelper.shared.disConnect(peripheral)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func userAction(_ sender: Any) {
        
        guard checkIsConnect() else {
            return
        }
        
        guard self.characteristic != nil else {
            return
        }
        
        guard let button = sender as? UIButton , let title = button.titleLabel?.text else { return }
        
        let passwordStr = PeripheralInfoHelper.shared.getManagerPassword(self.peripheral.name!)
        var orderStr = ""
        var numberStr = ""
        
        switch title {
        case "降锁":
            orderStr = "A01"
            numberStr = "00000"
            break
        case "升锁":
            orderStr = "A02"
            numberStr = "00000"
            break
        default:
            break
        }
        
        let order = passwordStr + "M" + orderStr + numberStr
        
        guard let characteristic = self.characteristic, let peripheral = self.peripheral else { return }
        
        peripheral.writeValue(BlueToothHelper.shared.dataFromString(order), for: characteristic, type: .withResponse)
    }
    
    func openReleaseAction() {
        guard checkIsConnect() else {
            return
        }
        guard self.characteristic != nil else {
            return
        }
        
        let order = PeripheralInfoHelper.shared.getManagerPassword(self.peripheral.name!) + "MU1000000"
        
        guard let characteristic = self.characteristic, let peripheral = self.peripheral else { return }
        
        peripheral.writeValue(BlueToothHelper.shared.dataFromString(order), for: characteristic, type: .withResponse)
        
    }
    
    @IBAction func downAction(_ sender: Any) {
        
    }
    
    @IBAction func startReleaseAction(_ sender: Any) {
       handleUploadButtonTapped()
    }
    
    //MARK: - NORDFUViewController implementation
    func handleAboutButtonTapped() {
//        self.showAbout(message: NORDFUConstantsUtility.getDFUHelpText())
         print(NORDFUConstantsUtility.getDFUHelpText())
    }
    
    func handleUploadButtonTapped() {
        
        guard dfuController != nil   else {
            self.performDFU()
            return
        }
        
        // Pause the upload process. Pausing is possible only during upload, so if the device was still connecting or sending some metadata it will continue to do so,
        // but it will pause just before seding the data.
        dfuController?.pause()
        
        let alert = UIAlertController(title: "Abort?", message: "Do you want to abort?", preferredStyle: .alert)
        let abort = UIAlertAction(title: "Abort", style: .destructive, handler: { (anAction) in
            _ = self.dfuController?.abort()
            self.clearUI()
            alert.dismiss(animated: true, completion: nil)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (anAction) in
            self.dfuController?.resume()
            alert.dismiss(animated: true, completion: nil)
        })
        
        alert.addAction(abort)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func updateUploadButtonState() {
        uploadButton.isEnabled = selectedFirmware != nil && peripheral != nil
    }
    
    func disableOtherButtons() {
        refreshButton.isEnabled = false
        for button in otherButtons {
            button.isEnabled = true
        }
    }
    
    func enableOtherButtons() {
        refreshButton.isEnabled = true
        for button in otherButtons {
            button.isEnabled = true
        }
    }
    
    func performDFU() {
        guard selectedFirmware != nil else {
            if let localPath = UserModel.shared.fileModel.localPath {
                self.selectedFirmware = DFUFirmware(urlToZipFile: URL.init(fileURLWithPath: localPath))
                self.performDFU()
            }
            else {
                
            }
            return
        }
        
        self.openReleaseAction()
        uploadStatus.text = "打开指令发送中..."
        uploadButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0, execute: {
            self.startDFU()
        })
        
        
        
        
    }
    
    func startDFU() {
        self.disableOtherButtons()
        
        progress.isHidden = false
        uploadButton.isEnabled = false
        
        self.registerObservers()
        
        // To start the DFU operation the DFUServiceInitiator must be used
        let initiator = DFUServiceInitiator(centralManager: BlueToothHelper.shared.centralManager, target: peripheral)
        
        initiator.alternativeAdvertisingNameEnabled = true
        initiator.peripheralSelector = self
        
        initiator.logger = self
        initiator.delegate = self
        initiator.progressDelegate = self
        
        dfuController = initiator.with(firmware: selectedFirmware!).start()
        uploadButton.setTitle("取消升级", for: UIControlState())
        uploadButton.isEnabled = true
    }
    
    func clearUI() {
        print("------------------ clear UI ------")
        DispatchQueue.main.async {
            self.dfuController          = nil
            self.isImportingFile = false
            
            self.progress.progress      = 0.0
            self.progress.isHidden      = true
            
            self.uploadButton.setTitle("开始升级", for: .normal)
            self.updateUploadButtonState()
            self.enableOtherButtons()
            self.removeObservers()
            
            BlueToothHelper.shared.resetCenterManager()
            
            self.activityIndicatorView.startAnimating()
            self.refreshButton.setTitle("未连接", for: UIControlState())
            self.characteristics.removeAll()
            self.characteristic = nil;
            
            BlueToothHelper.shared.connect(self.peripheral)
        }
    }
    
    func checkIsConnect() -> Bool {
        
        if (peripheral.state == .disconnected) {
            let alertVC = UIAlertController.init(title: "设备已断开", message: "重新连接？", preferredStyle: UIAlertControllerStyle.alert)
            
            alertVC.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (_) in
                BlueToothHelper.shared.connect(self.peripheral)
            }))
            alertVC.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (_) in
                
            }))
            
            navigationController?.present(alertVC, animated: true, completion: nil)
            
            return false
        }
        
        return true
    }
    
    func registerObservers() {
        if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert], categories: nil))
            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackgroundCallback), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActiveCallback), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        }
    }
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    @objc func applicationDidEnterBackgroundCallback() {
        if dfuController != nil {
            NORDFUConstantsUtility.showBackgroundNotification(message: "Uploading firmware...")
        }
    }
    
    @objc func applicationDidBecomeActiveCallback() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
}

extension PeripheralSettingViewController : LoggerDelegate {
    func logWith(_ level: LogLevel, message: String) {
        var levelString : String?
        switch(level) {
        case .application:
            levelString = "Application"
        case .debug:
            levelString = "Debug"
        case .error:
            levelString = "Error"
        case .info:
            levelString = "Info"
        case .verbose:
            levelString = "Verbose"
        case .warning:
            levelString = "Warning"
        }
        print("\(levelString!): \(message)")
    }
    
    
}

extension PeripheralSettingViewController : DFUServiceDelegate {
    //MARK: - DFUServiceDelegate
    func dfuStateDidChange(to state: DFUState) {
        isImportingFile = true
        switch state {
        case .connecting:
            uploadStatus.text = "Connecting..."
        case .starting:
            uploadStatus.text = "Starting DFU..."
        case .enablingDfuMode:
            uploadStatus.text = "Enabling DFU Bootloader..."
        case .uploading:
            uploadStatus.text = "Uploading..."
        case .validating:
            uploadStatus.text = "Validating..."
        case .disconnecting:
            uploadStatus.text = "Disconnecting..."
        case .completed:
            NORDFUConstantsUtility.showAlert(message: "Upload complete")
            if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded() {
                NORDFUConstantsUtility.showBackgroundNotification(message: "Upload complete")
            }
            self.clearUI()
            uploadStatus.text = "Completed!"
        case .aborted:
            NORDFUConstantsUtility.showAlert(message: "Upload aborted")
            if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded(){
                NORDFUConstantsUtility.showBackgroundNotification(message: "Upload aborted")
            }
            self.clearUI()
            uploadStatus.text = "Aborted..."
        }
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded() {
            NORDFUConstantsUtility.showBackgroundNotification(message: message)
        }
//        clearUI()
        DispatchQueue.main.async {
            self.uploadStatus.text = "Error: \(message)"
            self.uploadStatus.isHidden = false
            
            print(message)
        }
    }
}

extension PeripheralSettingViewController : DFUProgressDelegate {
    //MARK: - DFUProgressDelegate
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        self.progress.setProgress(Float(progress) / 100.0, animated: true)
//        progressLabel.text = String("\(progress)% (\(part)/\(totalParts))")
    }
}

extension PeripheralSettingViewController : DFUPeripheralSelectorDelegate {
    func select(_ peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber, hint name: String?) -> Bool {
        if self.peripheral == nil {
            return false
        }
        if peripheral.name == "DfuTarg" {
            return true
        }
        return peripheral.identifier == self.peripheral.identifier
    }
    
    func filterBy(hint dfuServiceUUID: CBUUID) -> [CBUUID]? {
        print(dfuServiceUUID)
        return [dfuServiceUUID]
    }
}

extension PeripheralSettingViewController : BlueToothHelperDelegate {
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        if peripheral.identifier == self.peripheral.identifier {
            print(peripheral.name)
        }
    }
    
    func discoverPeripheral(_ helper: BlueToothHelper, peripheral: CBPeripheral) {
        if self.isImportingFile {
            return
        }
        if peripheral.name == self.peripheral.name && self.peripheral != peripheral {
            self.peripheral = peripheral
            self.peripheral.delegate = helper
        }
        if self.peripheral.state == .disconnected {
            self.peripheral.delegate = helper
            BlueToothHelper.shared.connect(self.peripheral)
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService) {
        
        if peripheral == self.peripheral {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    
                    if serviceStrList.contains(characteristic.uuid.uuidString) {
                        if self.characteristics.contains(characteristic) == false {
                            self.characteristics.append(characteristic)
                        }
                        if characteristic.uuid.uuidString == characteristicUUIDString  && self.characteristic == nil {
                            self.characteristic = characteristic
                
                        }
                    }
                }
            }
        }
        
    }
    
    func centralManagerdidConnect(_ peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            activityIndicatorView.stopAnimating()
            refreshButton.setTitle("已连接", for: UIControlState())
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, value: String) {
       

    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func centralManagerDidConnect(_ peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            activityIndicatorView.stopAnimating()
            refreshButton.setTitle("已连接", for: UIControlState())
        }
    }
    
    func centralManagerDidDisconnectPeripheral(_ peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            activityIndicatorView.startAnimating()
            refreshButton.setTitle("未连接", for: UIControlState())
            characteristics.removeAll()
            characteristic = nil;
            BlueToothHelper.shared.connect(peripheral)
        }
    }
    
    func centralManagerDidFailToConnect(_ peripheral: CBPeripheral) {
        BlueToothHelper.shared.connect(peripheral)
    }
}

