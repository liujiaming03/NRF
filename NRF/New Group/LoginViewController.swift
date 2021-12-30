//
//  LoginViewController.swift
//  StopHereSwift
//
//  Created by yuszha on 2017/10/12.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD

class LoginViewController: UIViewController {

    @IBOutlet weak var mobile: UITextField!
    @IBOutlet weak var password: UITextField!
    var usename = ""
    let disposeBag = DisposeBag()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        mobile.text = UserModel.shared.mobile
//        password.text = UserModel.shared.password
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func loginAction(_ sender: Any) {
        
        guard let mobile = mobile.text , mobile.count > 0 else {
            SVProgressHUD.showError(withStatus: "请输入验证码")
            return
        }
        
        StopHereProvider.rx.mapRequest(.getOtaRecordByCode(mobile)).subscribe(onSuccess: { (result) in
            
            guard let resultData = result["resultData"] as? [String: String] else {
                return
            }
            
            let fileModel = DownloadFileModel.init(resultData)
    
            UserModel.shared.fileModel = fileModel
            UserModel.shared.download()
            
            PeripheralLocalInfoHelper.shared.updateLocalInfo()
            PeripheralInfoHelper.shared.batch = localIdentifier
            
            UserModel.shared.mobile = mobile

            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            let storyborad = UIStoryboard.init(name: "Main", bundle: nil)
            appdelegate.window?.rootViewController = storyborad.instantiateInitialViewController()
        }) { (error) in
            
        }.disposed(by: disposeBag)
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
