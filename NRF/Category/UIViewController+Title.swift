//
//  UIViewController+Title.swift
//  StopHere
//
//  Created by yuszha on 2017/7/20.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func custemImageTitle() {
        
        let image = UIImage.init(named: "WechatIMG13")
        
        let imageView = UIImageView.init(image: image)
        imageView.contentMode = .scaleAspectFit
        
        imageView.frame = CGRect.init(x: 0, y: 0, width: 60, height: 20.0)
        
        imageView.sizeToFit()
        
        navigationItem.titleView = imageView
    
    }
}
