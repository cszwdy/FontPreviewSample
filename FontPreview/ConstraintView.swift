//
//  TextView.swift
//  FontPreview
//
//  Created by Emiaostein on 4/27/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import UIKit

class ConstraintView: UIView {

    var elements: ([NSAttributedString.Glyph], [NSAttributedString.Line], NSAttributedString.Frame)?
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        // Drawing Texts, Lines, Frame
        guard let elements = elements else {return}
        
        // Frame
        let frame = elements.2
        let framePath = UIBezierPath(rect: frame.inConstraintFrame)
        UIColor.blackColor().setStroke()
        framePath.lineWidth = 6
        framePath.stroke()
        
        // Lines
        let lines = elements.1
        for line in lines {
            let linePath = UIBezierPath(rect: line.inConstraintFrame)
            UIColor.blueColor().setStroke()
            linePath.lineWidth = 0.5
            linePath.stroke()
            
            //// baseline Path
            let baseline = UIBezierPath()
            baseline.moveToPoint(CGPointMake(0, line.baselineOrigin.y))
            baseline.addLineToPoint(CGPointMake(line.inConstraintFrame.width, line.baselineOrigin.y))
            UIColor.redColor().setStroke()
            baseline.lineWidth = 0.5
            baseline.stroke()
        }
        
        // Texts
        let texts = elements.0
        for text in texts {
            let attributeText = text.attributeText
            attributeText.drawInRect(text.inConstraintDrawRect)
            
//            let glyphPath = UIBezierPath(rect: text.inConstraintDrawRect)
//            UIColor.lightGrayColor().setStroke()
//            glyphPath.lineWidth = 0.5
//            glyphPath.stroke()
            
            //// baseline Path
            let baseline = UIBezierPath()
            baseline.moveToPoint(CGPointMake(text.inConstraintDrawRect.maxX, text.inConstraintDrawRect.minY + text.inConstraintDrawRect.height * 0.4))
            baseline.addLineToPoint(CGPointMake(text.inConstraintDrawRect.maxX, text.inConstraintDrawRect.maxY - text.inConstraintDrawRect.height * 0.4))
            UIColor.lightGrayColor().setStroke()
            baseline.lineWidth = 1
            baseline.stroke()
        }
    }
}
