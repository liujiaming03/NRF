//
//  DownloadFileTableViewCell.swift
//  NRF
//
//  Created by yuszha on 2018/3/21.
//  Copyright © 2018年 yuszha. All rights reserved.
//

import UIKit

class DownloadFileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var fileSize: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    
    var userAction: ((DownloadFileModel) -> ())?
    
    var model : DownloadFileModel! {
        didSet {
            name.text = model.name
            fileSize.text = model.fileSize
            status.text = model.stutas == 0 ? "未下载" : ( model.stutas == 1 ? "下载完成" : "下载中" )
            statusButton.setTitle(model.stutas == 0 ? "开始下载" : ( model.stutas == 1 ? "删除下载" : "暂停下载" ), for: .normal)
        }
    }

    @IBAction func downloadAction(_ sender: Any) {
        userAction?(model)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
