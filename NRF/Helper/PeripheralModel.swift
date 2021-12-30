//
//  PeripheralModel.swift
//  StopHere
//
//  Created by yuszha on 2018/3/9.
//  Copyright © 2018年 yuszha. All rights reserved.
//

import UIKit
import RealmSwift

class PeripheralModel: Object {
    @objc dynamic var index : Int = 0
    @objc dynamic var isPass : Bool = false
    @objc dynamic var md5 : String = ""
    @objc dynamic var mpwd : String = ""
    @objc dynamic var pid : String = ""
    @objc dynamic var ssid : String = ""
    @objc dynamic var upwd : String = ""
    @objc dynamic var batch : String = ""
    
    func primaryKey() -> String? {
        return ssid
    }
    
    
}
