//
//  RequestAPI.swift
//  StopHereSwift
//
//  Created by yuszha on 2017/9/14.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import Foundation
import Moya
import Alamofire
import CryptoSwift

// MARK: - Provider setup

private func JSONResponseDataFormatter(_ data: Data) -> Data {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData =  try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return prettyData
    } catch {
        return data // fallback to original data if it can't be serialized.
    }
}

let StopHereProvider = MoyaProvider<StopHereTarget>(plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter)])



// MARK: - Provider support

private extension String {
    var urlEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}

public enum StopHereTarget {
    //登陆
    case getOtaRecordByCode(String)
    case getOtaRecord()
    case selectLockProduction(String)
}

let BASE_URL = "http://39.107.202.236:8086"
//let BASE_URL = "http://47.93.113.61:8086"



extension StopHereTarget: TargetType {

    public var baseURL: URL {
        
        switch self {
        case .getOtaRecordByCode(_):
            return URL(string:"http://39.107.202.236:8086")!
        case .getOtaRecord():
            return URL(string:BASE_URL)!
        case .selectLockProduction(_):
            return URL(string:"http://39.107.202.236:8086")!
        }
        
        
    }
    public var path: String {
        switch self {
        case .getOtaRecordByCode(_):
            return "/manage/blend/getOtaRecordByCode"
        case .getOtaRecord():
            return "manage/blend/getOtaRecord"
        case .selectLockProduction(_):
            return "manage/install/selectLockProduction"
        }
        
    }
    public var method: Moya.Method {
        return .post
    }
    public var parameters: [String: Any]? {
        switch self {
      
        default:
            return nil
        }
    }
    public var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    public var task: Task {
        switch self {
        case .getOtaRecordByCode(let password):
            return .requestJSONEncodable(["codes": password])
        case .getOtaRecord():
            return .requestJSONEncodable(["": ""])
        case .selectLockProduction(let batch):
            return .requestJSONEncodable(["batch": batch])
        }
        
    }
    public var validate: Bool {
        switch self {
        default:
            return false
        }
    }
    public var sampleData: Data {
        return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
    }
    public var headers: [String: String]? {
        return nil
    }
}



public func url(_ route: TargetType) -> String {
    return route.baseURL.appendingPathComponent(route.path).absoluteString
}

//MARK: - Response Handlers

extension Moya.Response {
    func mapNSArray() throws -> NSArray {
        let any = try self.mapJSON()
        guard let array = any as? NSArray else {
            throw MoyaError.jsonMapping(self)
        }
        return array
    }
}

