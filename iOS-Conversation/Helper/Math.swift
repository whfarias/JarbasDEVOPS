//
//  Math.swift
//  Phacil
//
//  Created by Rafael Moris on 06/01/17.
//  Copyright © 2017 Rafael Moris. All rights reserved.
//

import Foundation
import UIKit

class Math {
    
    class func random(min:Int, max:Int)-> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
    
    class func ruleOfThree(first:Double?, second:Double?, third:Double?, fourth:Double?)->Double? {
        
        if (first == nil && (second == nil || third == nil || fourth == nil)) {
            return nil
        }
        if (second == nil && (first == nil || third == nil || fourth == nil)) {
            return nil
        }
        if (third == nil && (first == nil || second == nil || fourth == nil)) {
            return nil
        }
        if (fourth == nil && (first == nil || second == nil || third == nil)) {
            return nil
        }
        
        var x:Double?
        if (first == nil && (second != nil && third != nil && fourth != nil)) {
            x = second! * third!
            x = x! / fourth!
        }
        if (second == nil && (first != nil && third != nil && fourth != nil)) {
            x = first! * fourth!
            x = x! / third!
        }
        if (third == nil && (first != nil && second != nil && fourth != nil)) {
            x = first! * fourth!
            x = x! / second!
        }
        if (fourth == nil && (first != nil && second != nil && third != nil)) {
            x = second! * third!
            x = x! / first!
        }
        return x
    }
    
    static func angleBetween(pointA:CGPoint, pointB:CGPoint, center:CGPoint) ->CGFloat {
        let v1 = CGVector(dx: pointA.x - center.x, dy: pointA.y - center.y)
        let v2 = CGVector(dx: pointB.x - center.x, dy: pointB.y - center.y)
        
        let angle = atan2(v2.dy, v2.dx) - atan2(v1.dy, v1.dx)
        
        return angle
    }
    
    static func distance(from p1:CGPoint, to p2:CGPoint)->CGFloat {
        let legA = p1.x - p2.x
        let legB = p1.y - p2.y
        return sqrt(pow(legA, 2) + pow(legB, 2))
    }
    
    static func firstVectorHasMinorSize(v1:CGPoint, v2:CGPoint, origin:CGPoint)->Bool {
        let legA1 = origin.x - v1.x
        let legB1 = origin.y - v1.y
        let hypotenuse1 = sqrt(pow(legA1, 2) + pow(legB1, 2))
        
        let legA2 = origin.x - v2.x
        let legB2 = origin.y - v2.y
        let hypotenuse2 = sqrt(pow(legA2, 2) + pow(legB2, 2))
        
        return hypotenuse1 < hypotenuse2
    }
}
