//
//  PeripheralInfoHelper.swift
//  StopHere
//
//  Created by yuszha on 2017/8/18.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import UIKit
import CryptoSwift
import RxSwift

import RealmSwift
import SVProgressHUD

let localIdentifier = "ed"

class PeripheralLocalInfoHelper: NSObject {
    
    static let shared = PeripheralLocalInfoHelper()
    
    var localMap : Array<Dictionary<String, String>>? = {
        
        guard
            let localPath = Bundle.main.path(forResource: "result", ofType: ".plist") else {
                return nil
        }
        return NSArray.init(contentsOfFile: localPath) as? Array<Dictionary<String, String>>
        
    }()
    
    func updateLocalInfo() {
        let batch = localIdentifier;
        guard let list = localMap else {
            return
        }
        if let realm = try? Realm() {
            try? realm.write {
                let models = realm.objects(PeripheralModel.self).filter("batch == \'\(batch)\'")
                realm.delete(models)
            }
            
            BlueToothHelper.shared.currentIndex = 1
            var index = 1
            for object in list {
                let model = PeripheralModel()
                
                if let md5 = object["md5"] {
                    model.md5 = md5
                }
                if let mpwd = object["mpwd"] {
                    model.mpwd = mpwd
                }
                if let pid = object["pid"] {
                    model.pid = pid
                }
                if let ssid = object["ssid"] {
                    model.ssid = ssid
                }
                if let upwd = object["upwd"]  {
                    model.upwd =  upwd
                }
                model.batch = batch
                model.index = index
                index += 1
                try? realm.write {
                    realm.add(model)
                }
            }
        }
    }

}

class PeripheralInfoHelper: NSObject {
    
    static let shared = PeripheralInfoHelper()
    
    var batch : String? {
        get {
            return UserDefaults.standard.value(forKey: "BlueToothHelperCurrentBatch") as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "BlueToothHelperCurrentBatch")
        }
    }
    
 
    
    func getAddedBatch() -> Array<String> {
        var list = Array<String>()
        
        guard let realm = try? Realm() else {
            return list
        }
        let models = realm.objects(PeripheralModel.self).distinct(by: ["batch"])
        for model in models.reversed() {
            list.append(model.batch)
        }
        return list
    }
   
    func reset(_ list: Array<Dictionary<String, Any>>, batch: String) {
        if let realm = try? Realm() {
            try? realm.write {
                let models = realm.objects(PeripheralModel.self).filter("batch == \'\(batch)\'")
                realm.delete(models)
            }
    
            BlueToothHelper.shared.currentIndex = 1
            var index = 1
            for object in list {
                let model = PeripheralModel()
   
                if let md5 = object["pIdMd"] as? String {
                    model.md5 = md5
                }
                if let mpwd = object["mangerCode"] as? Int {
                    model.mpwd = intToSixCharString(mpwd)
                }
                if let pid = object["pId"] as? String {
                    model.pid = pid
                }
                if let ssid = object["ssId"] as? String {
                    model.ssid = ssid
                }
                if let upwd = object["userCode"] as? Int {
                    model.upwd =  intToSixCharString(upwd)
                }
                model.batch = batch
                model.index = index
                index += 1
                try? realm.write {
                    realm.add(model)
                }
            }
        }
    }
    
    func intToSixCharString(_ number : Int) -> String {
        var str = String(number)
        while str.count < 6 {
            str = "0" + str
        }
        return str
    }
    
    
    func getMap(_ index : Int) -> Dictionary<String, String>? {
        guard let batch = batch else {
            return nil
        }
        guard let realm = try? Realm() , let model = realm.objects(PeripheralModel.self).filter("batch = \'\(batch)\' AND index == \(index)").first else {
            return nil
        }
        
        var map = Dictionary<String, String>()
        map["index"] = "\(index)"
        map["md5"] = model.md5
        map["mpwd"] = model.mpwd
        map["pid"] = model.pid
        map["ssid"] = model.ssid
        map["upwd"] = model.upwd
        
        return map
    }
    
    func getMap( ssid : String) -> Dictionary<String, String>? {
    
        guard let realm = try? Realm() , let model = realm.objects(PeripheralModel.self).filter("ssid == \'\(ssid)\'").first else {
            return nil
        }
        
        var map = Dictionary<String, String>()
        map["index"] = "\(model.index)"
        map["md5"] = model.md5
        map["mpwd"] = model.mpwd
        map["pid"] = model.pid
        map["ssid"] = model.ssid
        map["upwd"] = model.upwd
        
        return map
        
    }
    
    func getUserPassword(_ ssid : String) -> String {
        
        guard let realm = try? Realm() , let model = realm.objects(PeripheralModel.self).filter("ssid == \'\(ssid)\'").first else {
            return "111111"
        }

        return model.upwd
        
    }
    
    func getManagerPassword(_ ssid : String) -> String {
        
        guard let realm = try? Realm() , let model = realm.objects(PeripheralModel.self).filter("ssid == \'\(ssid)\'").first else {
            return "888888"
        }
        
        return model.mpwd
        
    }
    
}

public extension String {
    
    
    public func hexStringToArray() -> Array<UInt8> {
        
        var result = Array<UInt8>()
        
        var number = ""
        
        Array(self).forEach { (c) in
            number = number + "\(c)"
            if number.count == 2 {
                result.append(hexStringToInt(str: number))
                number = ""
            }
        }
        
        return result
        
    }
    
    public func hexStringToInt(str: String) -> UInt8 {
        var result:UInt32 = 0
        Scanner(string: str).scanHexInt32(&result)
        return UInt8(result)
    }
}
