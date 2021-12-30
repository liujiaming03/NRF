//
//  MainTableViewController.swift
//  StopHere
//
//  Created by yuszha on 2017/7/19.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import UIKit
import CoreBluetooth
import MJRefresh

class MainTableViewController: UITableViewController {
    
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "OTA"
        
        
        BlueToothHelper.shared.addDelegate(self)
        BlueToothHelper.shared.discoverPeripherals()
        
        tableView.register(UINib.init(nibName: "MainTableViewCell", bundle: nil), forCellReuseIdentifier: "MainTableViewCell")
        tableView.tableFooterView = UIView()
        
        
        tableView.mj_header = MJRefreshStateHeader.init(refreshingTarget: self, refreshingAction: #selector(MainTableViewController.refreshAction as (MainTableViewController) -> () -> ()))

    }
    
    @objc func refreshAction() {
        BlueToothHelper.shared.reDiscoverPeripherals()
        tableView.mj_header.endRefreshing()
        activityIndicatorView.startAnimating()
        refreshButton.setTitle("停止", for: UIControlState())
    }
    
    
    deinit {
        BlueToothHelper.shared.removeDelegate(self)
    }

    
    @IBAction func refreshAction(_ sender: UIButton) {
        if sender.titleLabel?.text == "停止" {
            activityIndicatorView.stopAnimating()
            sender.setTitle("刷新", for: UIControlState())
            BlueToothHelper.shared.stopDiscoverPeripherals()
        }
        else {
            activityIndicatorView.startAnimating()
            sender.setTitle("停止", for: UIControlState())
            BlueToothHelper.shared.discoverPeripherals()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return BlueToothHelper.shared.peripherals.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainTableViewCell") as! MainTableViewCell
        
        if indexPath.row < BlueToothHelper.shared.peripherals.count {
            let peripheral = BlueToothHelper.shared.peripherals[indexPath.row]
            cell.peripheral = peripheral
        }
        
        // Configure the cell...

        return cell
    }
 
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row < BlueToothHelper.shared.peripherals.count {
            let vc = PeripheralSettingViewController()
            
            let peripheral = BlueToothHelper.shared.peripherals[indexPath.row]
            BlueToothHelper.shared.connect(peripheral)
            
            vc.peripheral = peripheral
            
            navigationController?.pushViewController(vc, animated: true)
            vc.hidesBottomBarWhenPushed = true
        }

    }
    

    

}


extension MainTableViewController : BlueToothHelperDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    
    }
    
    func discoverPeripheral(_ helper: BlueToothHelper , peripheral: CBPeripheral) {
        self.tableView.reloadData()
    }
}
