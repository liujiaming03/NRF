//
//  DownloadFileTableViewController.swift
//  NRF
//
//  Created by yuszha on 2018/3/21.
//  Copyright © 2018年 yuszha. All rights reserved.
//

import UIKit
import RxSwift
import Alamofire
import RealmSwift


class DownloadFileRealmModel: Object {
    
    @objc var name : String = ""
    @objc var path : String = ""
    @objc var localPath : String = ""
    
    @objc override class func primaryKey() -> String? { return "name" }
}


class DownloadFileModel: NSObject {
    
    var name : String!
    var path : String!
    var fileSize : String!
    var stutas = 0 {
        didSet {
            updateSize()
        }
    }// 0 下载中， 1 已下载 2 下载中
    
    var localPath : String! {
        get {
            guard  let name = name , let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last else {
                return nil
            }
            return path + "/" +  name + ".zip"
        }
    }
    
    
    var request: DownloadRequest?
    
    
    func updateSize() {
        guard  let filePath = self.localPath else {
            return
        }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            if let attributes = try? fileManager.attributesOfItem(atPath: filePath),
                let size = attributes[FileAttributeKey.size] as? Int {
                fileSize = String.init(format: "%.2fKB", Double(size) / 1024.0)
            }
            else {
                fileSize = "0KB"
            }
        }
        else {
            fileSize = "0KB"
        }
    }
    
    func getStatus() {
        guard  let filePath = self.localPath else {
            return
        }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            stutas = 1
            if let attributes = try? fileManager.attributesOfItem(atPath: filePath),
                let size = attributes[FileAttributeKey.size] as? Int {
                fileSize = String.init(format: "%.2fKB", Double(size) / 1024.0)
            }
            else {
                fileSize = "0KB"
            }
        }
        else {
            stutas = 0
            fileSize = "0KB"
        }
    }
    
    init(_ map: Dictionary<String, String>) {
        super.init()
        name = map["name"]
        path = map["url"]
        getStatus()
        if let realm = try? Realm() {
            try? realm.write { [weak self] in
                guard let `self` = self else {
                    return
                }
                let model = DownloadFileRealmModel()
                model.name = self.name
                model.localPath = self.localPath
                model.path = self.path
//                realm.add(model, update: true)
                realm.add(model, update: .all)
            }
        }
    }
}

class DownloadFileTableViewController: UITableViewController {

    let disposeBag = DisposeBag()
    var models = [DownloadFileModel]()
    
    var selectAction : ((DownloadFileModel) -> ())!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "下载列表"
        
        tableView.register(UINib.init(nibName: "DownloadFileTableViewCell", bundle: nil), forCellReuseIdentifier: "DownloadFileTableViewCell")
        
        tableView.backgroundColor = UIColor.groupTableViewBackground
        view.backgroundColor = UIColor.groupTableViewBackground

        StopHereProvider.rx.mapRequest(.getOtaRecord()).subscribe(onSuccess: { [weak self] (response) in
            guard let `self` = self, let list = response["resultData"] as? [[String: String]] else {
                return
            }
            for map in list {
                let model = DownloadFileModel.init(map)
                self.models.append(model)
            }
            self.tableView.reloadData()
        }) { (error) in
            
        }.disposed(by: disposeBag)

        self.tableView.tableFooterView = UIView()
        self.tableView.separatorStyle = .none
        
    }
    
    func download(_ model: DownloadFileModel) {
        
        guard let url = model.path else {
            return
        }
        
        guard let filePath = model.localPath else {
            return
        }
        
        let destination : DownloadRequest.DownloadFileDestination = { temporaryURL, response in
            return (URL.init(fileURLWithPath: filePath), [])
        }
        
        let request = Alamofire.download(url, to: destination)
        model.request = request
        model.stutas = 2
        self.tableView.reloadData()
        request.downloadProgress { (progress) in
            model.stutas = 2
            self.tableView.reloadData()
        }
        request.response { (response) in
            model.stutas = 1
            self.tableView.reloadData()
        }
        
    }
    
    func cancel (_ model: DownloadFileModel) {
        if let request = model.request {
            request.cancel()
            model.request = nil
        }
        delete(model)
    }
    
    func delete (_ model: DownloadFileModel) {
        if let filePath = model.localPath  {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                try? fileManager.removeItem(atPath: filePath)
            }
        }
        
        model.stutas = 0
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return models.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 102.0
    }

 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadFileTableViewCell", for: indexPath) as! DownloadFileTableViewCell
        
        cell.model = models[indexPath.row]
        cell.userAction = { model in
            switch model.stutas {
            case 0:
                self.download(model)
            case 1:
                self.delete(model)
            case 2:
                self.cancel(model)
            default:
                break
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = models[indexPath.row]
        if model.stutas == 1 {
            selectAction(models[indexPath.row])
            self.navigationController?.popViewController(animated: true)
        }
        else if model.stutas == 0 {
            let alert = UIAlertController.init(title: "文件未下载", message: "开始下载", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { [weak self] (_) in
                self?.download(model)
            }))
            alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (_) in
                
            }))
            present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController.init(title: "文件正在下载", message: "请等待下载完成", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: {  (_) in
                
            }))
  
            present(alert, animated: true, completion: nil)
        }
    }

}
