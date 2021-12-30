//
//  RequestRxExtension.swift
//  StopHereManager
//
//  Created by yuszha on 2018/2/26.
//  Copyright © 2018年 yuszha. All rights reserved.
//
import Foundation
import RxSwift

import Moya

enum RequestError : Error {
    case noData
    case errorCode
}

public extension Reactive where Base: MoyaProviderType {

    public func mapRequest(_ token: Base.Target, callbackQueue: DispatchQueue? = nil) -> Single<Dictionary<String, Any>> {
        return Single.create { [weak base] single in
            let cancellableToken = base?.request(token, callbackQueue: callbackQueue, progress: nil) { result in
                switch result {
                case let .success(response):
                    if let map = try? response.mapJSON() as? Dictionary<String, Any> {
                        if let errorCode = map?["errCode"] as? Int , errorCode == 1 {
                            single(.success(map!))
                            return
                        }
                        
                        single(.error(RequestError.errorCode))
                        return
                    }
                    single(.error(RequestError.noData))
                case let .failure(error):
                    single(.error(error))
                }
            }
            
            return Disposables.create {
                cancellableToken?.cancel()
            }
        }
    }
}
