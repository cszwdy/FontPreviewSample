//
//  TextInfo.swift
//  FontPreview
//
//  Created by Emiaostein on 4/24/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import Foundation
import UIKit

struct TextInfo {
    let origin: CGPoint
    let size: CGSize
    var color: UIColor = UIColor.redColor()
    
    var rect: CGRect {
        return CGRect(origin: origin, size: size)
    }
    var center: CGPoint {
        return CGPoint(x: origin.x / 2.0, y: origin.y / 2.0)
    }
}

func drawTextInfos(infos: [TextInfo]) {
    
    for info in infos {
        let rectanglePath = UIBezierPath(rect: info.rect)
        info.color.setStroke()
        rectanglePath.lineWidth = 0.5
        rectanglePath.stroke()
    }
}