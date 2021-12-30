//
//  MainTableViewCell.swift
//  StopHere
//
//  Created by yuszha on 2017/7/21.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import UIKit
import CoreBluetooth

class MainTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    
    deinit {
        BlueToothHelper.shared.removeDelegate(self)
    }
    
    var peripheral : CBPeripheral? {
        didSet {
            nameLabel.text =  BlueToothHelper.shared.nameMap[peripheral!.identifier.uuidString] != nil ? (BlueToothHelper.shared.nameMap[peripheral!.identifier.uuidString]!.characters.count != 0) ? BlueToothHelper.shared.nameMap[peripheral!.identifier.uuidString] : "未知设备" : "未知设备"
//            if peripheral?.state != .connected {
//                rssiLabel.text = "未连接"
//            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        BlueToothHelper.shared.addDelegate(self)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

extension MainTableViewCell : BlueToothHelperDelegate {
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber) {
        
        if peripheral == self.peripheral {
            rssiLabel.text = "RSSI:" + "\(RSSI.intValue)" + "dB"
        }
        
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            nameLabel.text = BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] != nil ? (BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString]!.characters.count != 0) ? BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] : "未知设备" : "未知设备"
        }
    }
}
