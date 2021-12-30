//
//  SelectLocksViewController.swift
//  StopHere
//
//  Created by yuszha on 2018/3/9.
//  Copyright © 2018年 yuszha. All rights reserved.
//

import UIKit
import SCLAlertView
import RxSwift
import SVProgressHUD

class SelectLocksViewController: UITableViewController {
    
    var batchs = PeripheralInfoHelper.shared.getAddedBatch()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    @IBAction func addBatchAction(_ sender: Any) {
        let alertView = SCLAlertView()
        let textField = alertView.addTextField()
        alertView.addButton("确定") { [weak self] in
            if let number = textField.text , number.count > 0 {
                if (number == localIdentifier) {
                    PeripheralLocalInfoHelper.shared.updateLocalInfo()
                    SVProgressHUD.showSuccess(withStatus: "添加成功")
                    self?.batchs = PeripheralInfoHelper.shared.getAddedBatch()
                    PeripheralInfoHelper.shared.batch = localIdentifier
                    self?.tableView.reloadData()
                }
                else {
                    self?.reuquestData(number)
                }
                
            }
        }
        alertView.showEdit("请输入序号", subTitle: "", closeButtonTitle: "取消")
    }
    
    
    
    func reuquestData(_ identifier : String) {
        StopHereProvider.rx.request(.selectLockProduction(identifier)).subscribe(onSuccess: { [weak self] (respose) in
            if let result = try? respose.mapJSON() as? Dictionary<String, Any>, let list = result?["resultData"] as? Array<Dictionary<String, Any>>, list.count > 0 {
                PeripheralInfoHelper.shared.reset(list, batch: identifier)
                SVProgressHUD.showSuccess(withStatus: "添加成功")
                self?.batchs = PeripheralInfoHelper.shared.getAddedBatch()
                self?.tableView.reloadData()
                PeripheralInfoHelper.shared.batch = identifier
                self?.tableView.reloadData()
            }
            else {
                SVProgressHUD.showSuccess(withStatus: "添加失败")
            }
        }) { (error) in
            
        }.disposed(by: disposeBag)
        
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
        return batchs.count
    }

    
 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")

        if cell == nil {
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "reuseIdentifier")
        }
        cell?.textLabel?.text  = batchs[indexPath.row]
        // Configure the cell...
        cell?.detailTextLabel?.text = (batchs[indexPath.row] == PeripheralInfoHelper.shared.batch) ? "当前": nil
        
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PeripheralInfoHelper.shared.batch = batchs[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        SVProgressHUD.showSuccess(withStatus: "已选择批次：\(batchs[indexPath.row])")
        self.tableView.reloadData()
    }

}
