//
//  String+E.swift
//  ExpandC_Swift
//
//  Created by YLCHUN on 15/10/20.
//  Copyright © 2015年 ylchun. All rights reserved.
//

import Foundation
import UIKit
extension String {
    
    /**计算文本在指定宽度内的高度*/
    func heightInWeight(_ font:UIFont? = nil,weight:CGFloat)->CGFloat{
        var font = font
        if font==nil{
            font = UIFont(name: "Helvetica", size: 17)
        }
        let options : NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let boundingRect = self.boundingRect(with: CGSize(width: weight, height: 0), options: options, attributes: [NSAttributedStringKey.font:font!], context: nil)
        return boundingRect.height
    }
    
    func positionOf(_ sub:String)->Int {
        var pos = -1
        if let range = self.range(of: sub) {
            if !range.isEmpty {
                pos = self.distance(from: self.startIndex, to: range.lowerBound)
            }
        }
        return pos
    }
    
    func subString(from: Int)->String {
        var substr = ""
        let start = self.characters.index(self.startIndex, offsetBy: from)
        let end = self.endIndex
        //		println("String: \(self), start:\(start), end: \(end)")
        let range = start..<end
        substr = String(self[range])
        //		println("Substring: \(substr)")
        return substr
    }
    
    func subString(to: Int)->String {
        var substr = ""
        let end = self.characters.index(self.startIndex, offsetBy: min(to, self.length-1))
        let range = self.startIndex...end
        substr = String(self[range])
        return substr
    }
    
    func subString(from: Int, to: Int)->String{
        var substr = ""
        let start = self.characters.index(self.startIndex, offsetBy: from)
        let end = self.characters.index(self.startIndex, offsetBy: min(to, self.length-1))
        let range = start...end
        substr = String(self[range])
        return substr
    }
    
    func subString(from: Int, length: Int)->String{
        var substr = ""
        let start = self.characters.index(self.startIndex, offsetBy: from)
        let end = self.characters.index(self.startIndex, offsetBy: min(from+length, self.length)-1)
        let range = start...end
        substr = String(self[range])
        return substr
    }
    
    func subString(to: Int, length: Int)->String{
        var substr = ""
        let start = self.characters.index(self.startIndex, offsetBy: max(to-length+1, 0))
        let end = self.characters.index(self.startIndex, offsetBy: to)
        let range = start...end
        substr = String(self[range])
        return substr
    }
    
    /**
    *邮箱验证
    */
     var isEmail:Bool{
        let regex="^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$"
        return doRegex(regex)
    }

    /**
    *电话号码验证
    */
     var isPhoneNum:Bool{
        let regex="(^((13[0-9])|(15[^4,\\D])|(18[0,0-9]))\\d{8}$)|(\\d{3}-\\d{8}|\\d{4}-\\d{7}|\\d{4}-\\d{8})"
        return doRegex(regex)
    }
    
    //执行验证
    func doRegex(_ regex:String)->Bool{
        var result:Bool=false
        var expression:NSRegularExpression
        do{
            expression = try NSRegularExpression(pattern: regex, options: NSRegularExpression.Options.caseInsensitive  )
            let matches = expression.matches(in: self, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, self.length))
            result = matches.count > 0
        }
        catch
        {
            print(error)
            result=false
        }
        return result
    }
    
    //获取汉子拼音
     var pinYin:String{
        get{
            let str=NSMutableString(string: self)
            let cfStr:CFMutableString = str as CFMutableString
            //转成了可变字符串
            CFStringTransform(cfStr,nil, kCFStringTransformMandarinLatin,false)
            //再转换为不带声调的拼音
            CFStringTransform(cfStr,nil, kCFStringTransformStripDiacritics,false)
            //转化为大写拼音
            //let  pinYin = str.capitalizedString
            return str as String
        }
    }
    
    //长度
     var length:Int{
        return self.count
    }
    var intValue: Int?{return NumberFormatter().number(from: self)?.intValue}
    var floatValue: Float? {return NumberFormatter().number(from: self)?.floatValue}
    var doubleValue: Double? {return NumberFormatter().number(from: self)?.doubleValue}
}
/*
 infix operator || : LogicalDisjunctionPrecedence
 infix operator && : LogicalConjunctionPrecedence
 infix operator < : ComparisonPrecedence
 infix operator <= : ComparisonPrecedence
 infix operator > : ComparisonPrecedence
 infix operator >= : ComparisonPrecedence
 infix operator == : ComparisonPrecedence
 infix operator != : ComparisonPrecedence
 infix operator === : ComparisonPrecedence
 infix operator !== : ComparisonPrecedence
 infix operator ~= : ComparisonPrecedence
 infix operator ?? : NilCoalescingPrecedence
 infix operator + : AdditionPrecedence
 infix operator - : AdditionPrecedence
 infix operator &+ : AdditionPrecedence
 infix operator &- : AdditionPrecedence
 infix operator | : AdditionPrecedence
 infix operator ^ : AdditionPrecedence
 infix operator * : MultiplicationPrecedence
 infix operator / : MultiplicationPrecedence
 infix operator % : MultiplicationPrecedence
 infix operator &* : MultiplicationPrecedence
 infix operator & : MultiplicationPrecedence
 infix operator << : BitwiseShiftPrecedence
 infix operator >> : BitwiseShiftPrecedence
 infix operator ..< : RangeFormationPrecedence
 infix operator ... : RangeFormationPrecedence
 infix operator *= : AssignmentPrecedence
 infix operator /= : AssignmentPrecedence
 infix operator %= : AssignmentPrecedence
 infix operator += : AssignmentPrecedence
 infix operator -= : AssignmentPrecedence
 infix operator <<= : AssignmentPrecedence
 infix operator >>= : AssignmentPrecedence
 infix operator &= : AssignmentPrecedence
 infix operator ^= : AssignmentPrecedence
 infix operator |= : AssignmentPrecedence
 */
infix operator =? : RegexPrecedence
precedencegroup RegexPrecedence {
    associativity: none//none  left right ;associativity: left 表示左结合
    higherThan: LogicalDisjunctionPrecedence
    lowerThan: MultiplicationPrecedence
}

func =? (lhs: String, rhs: String) -> Bool {
    return lhs.doRegex(lhs)
}
