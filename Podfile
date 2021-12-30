use_frameworks!

inhibit_all_warnings!

target "NRF" do
    pod 'iOSDFULibrary'
    
    # 网络
    pod 'Moya/RxSwift'
    pod 'SwiftyJSON'
    pod 'SVProgressHUD'
    pod 'MJRefresh'
    
    pod 'RxCocoa'
    pod 'RxSwift'
    pod 'BuglyHotfix'
    pod 'SCLAlertView', '~>0.8.0'
# 数据库
    pod 'RealmSwift'
    pod 'CryptoSwift'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        puts #{target.name}
    end
end
