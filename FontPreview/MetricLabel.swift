//
//  MetricLabel.swift
//  FontPreview
//
//  Created by Emiaostein on 4/24/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import UIKit

class TextLayer: CATextLayer {
    var drawingRect: CGRect!
    
    override func drawInContext(ctx: CGContext) {

        CGContextSaveGState(ctx)
        CGContextTranslateCTM(ctx, drawingRect.minX, drawingRect.minY)
        super.drawInContext(ctx)
        CGContextRestoreGState(ctx)
    }
}

class MetricLabel: UILabel {
    
    var debug: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    var count: CGFloat = 2
    private var infos: [NSAttributedString.TextUnit] {
        return attributedText?.generateTextUnitsIn(CGRect(x: 0, y: 0, width: bounds.width / count, height: bounds.height)) ?? []
    }
    
    override func drawTextInRect(rect: CGRect) {
        
        
        if debug {
            super.drawTextInRect(CGRect(x: 0, y: 0, width: bounds.width / count, height: bounds.height))
            drawTextUnit(infos)
        } else {
            super.drawTextInRect(CGRect(x: 0, y: 0, width: bounds.width / count, height: bounds.height))
        }
    }
    
    func drawTextUnit(infos: [NSAttributedString.TextUnit]) {
        
        layer.sublayers?.forEach({ (alayer) in
            if let t = alayer as? TextLayer {
                t.removeFromSuperlayer()
            }
        })
        for info in infos {
            
            let constraintPath = UIBezierPath(rect: info.constraintRect)
            UIColor.redColor().setStroke()
            constraintPath.lineWidth = 0.5
            constraintPath.stroke()
            
            let rectanglePath = UIBezierPath(rect: info.usedRect)
            UIColor.blueColor().setStroke()
            rectanglePath.lineWidth = 0.5
            rectanglePath.stroke()
            
            let sectionPath = UIBezierPath(rect: info.sectionRect)
            print("sectionRect = \(info.sectionRect)")
            UIColor.redColor().setStroke()
            sectionPath.lineWidth = 0.5
            sectionPath.stroke()
            
            let textPath = UIBezierPath(rect: info.frame)
            UIColor.darkGrayColor().setStroke()
            textPath.lineWidth = 0.5
            textPath.stroke()
            
////            draw text
//            let attributeText = NSAttributedString(string: info.text, attributes: info.attributes)
//            attributeText.drawInRect(info.typographicRect)

            //text layer
            let textLayer = TextLayer()
            textLayer.contentsScale = UIScreen.mainScreen().scale
            textLayer.drawingRect = info.drawingRect
            textLayer.frame = info.frame
            textLayer.string = info.attributeString
//            textLayer.borderWidth = 1
//            textLayer.borderColor = UIColor.lightGrayColor().CGColor
            layer.addSublayer(textLayer)
        }
    }
}


extension NSAttributedString {
    
    struct TextUnit {
        let text: String
        let attributes: [String: AnyObject]?

        let origin: CGPoint  // the real text view position
        let size: CGSize  // the real text view size
        let typographicRect: CGRect  // the text view draw rect
        let section: Int
        let inSectionglyphIndex: Int
        let inAllGlyphIndex: Int
        let constraintRect: CGRect  // constraint the texts
        let usedSize: CGSize // text bounding size
        let sectionRect: CGRect  // line rect
        var drawingRect: CGRect {
            return CGRect(origin: CGPoint(x: typographicRect.minX - origin.x, y: typographicRect.minY - origin.y), size: typographicRect.size)
        }
        
        var usedRect: CGRect {
            return CGRect(x: 0.5 * (constraintRect.width - usedSize.width), y: 0.5 * (constraintRect.height - usedSize.height), width: usedSize.width, height: usedSize.height)
        }
        
        var indexPath: (section: Int, index: Int) {
            return (section, inSectionglyphIndex)
        }
        var frame: CGRect {
            return CGRect(origin: origin, size: size)
        }
        var anchorPoint: CGPoint {
            return CGPoint(x: drawingRect.midX / size.width, y: drawingRect.midY / size.height)
        }
        var position: CGPoint {
            let anchor = anchorPoint
            return CGPoint(x: origin.x + anchor.x * size.width, y: origin.y + anchor.y * size.height)
        }
        var sectionCenter: CGPoint {
            return CGPoint(x: sectionRect.midX, y: sectionRect.minY)
        }
        var attributeString: NSAttributedString {
            return NSAttributedString(string: text, attributes: attributes)
        }
    }
    
    func generateTextUnitsIn(constraintRect: CGRect) -> [TextUnit] {
        
        let storage = NSTextStorage(attributedString: self)
        let container = NSTextContainer(size: constraintRect.size)
        let manager = NSLayoutManager()
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        
        let constraintSize = constraintRect.size
        let bounds = CGRect(origin: CGPoint.zero, size: constraintSize)
        let pathRect = bounds
        let frameSetter = CTFramesetterCreateWithAttributedString(self)
        let textSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, 0), nil, constraintSize, nil)  // enclosed texts rect
        
        // CTFrame
        let path = CGPathCreateWithRect(pathRect, nil)
        let framer = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        
        // CTLines
        let lines = CTFrameGetLines(framer)
        let lineCount = CFArrayGetCount(lines)
        let lineBaseLineOrigins: [CGPoint] = {
            var origins = Array(count: lineCount, repeatedValue: CGPoint.zero)
           CTFrameGetLineOrigins(framer, CFRangeMake(0, 0), &origins)
            return origins
        }()
        
        var glyphLocation = 0
        var nextGlyphLocation = 0
        var infos = [TextUnit]()
        
        for i in 0..<lineCount {
            // CTLine
            let lineBaseLineOrigin = lineBaseLineOrigins[i] // fliped line baseline origin
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, i), CTLine.self)
            
            var lineAscent: CGFloat = 0
            var lineDecent: CGFloat = 0
            var lineCap: CGFloat = 0
            let width = CTLineGetTypographicBounds(line, &lineAscent, &lineDecent, &lineCap)
            let imageBounds = CTLineGetImageBounds(line, nil)
            let lineHeight = lineAscent + lineDecent + lineCap
            let lineWhiteSpace = CTLineGetTrailingWhitespaceWidth(line)
            
            let lineSize = CGSize(width: CGFloat(width), height: lineHeight)
            let lineOrigin = CGPointApplyAffineTransform(CGPoint(x: lineBaseLineOrigin.x, y: lineBaseLineOrigin.y), CGAffineTransformConcat(CGAffineTransformMakeScale(1, -1), CGAffineTransformMakeTranslation(0, bounds.height + 0.5 * (bounds.height - textSize.height) - lineAscent)))
            
            // Line Rect
            let lineRect = CGRect(origin: lineOrigin, size: lineSize)
            print("lineRect = \(lineRect), lineBaseLineOrigin = \(lineBaseLineOrigin), imageBounds = \(imageBounds), lineWhiteSpace = \(lineWhiteSpace), width = \(width)")
            
            // line String
//            let stringRange = CTLineGetStringRange(line)
//            print((string as NSString).substringWithRange(NSMakeRange(stringRange.location, stringRange.length)))
            
            // CTRuns
            let runs = CTLineGetGlyphRuns(line)
            let runCount = CFArrayGetCount(runs)
            
            for j in 0..<runCount {
                // Run
                let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, j), CTRun.self)
                
                // CGGlyphs
                let glyphCount = CTRunGetGlyphCount(run)
                let glyphPostions: [CGPoint] = {
                    var positions = Array(count: glyphCount, repeatedValue: CGPoint.zero)
                    CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
                    return positions
                }()
                
                let firstGlyphInRunPosition = glyphPostions[0]
                let runPosition = firstGlyphInRunPosition
                
                for n in 0..<glyphCount {
                    
                     // characters in glyph
                    if glyphLocation < nextGlyphLocation {
                        glyphLocation += 1
//                        continue
                    }
                    var actualGlyphRange: NSRange = NSMakeRange(0, 0)
                    let characterRange = manager.characterRangeForGlyphRange(NSMakeRange(glyphLocation, 1), actualGlyphRange: &actualGlyphRange)
                    
                    let charaters = (string as NSString).substringWithRange(characterRange)
                    print("\(characterRange): \(charaters)")
                    
                    var attributes = attributesAtIndex(characterRange.location, effectiveRange: nil)
                    attributes[NSParagraphStyleAttributeName] = nil
                    attributes[NSForegroundColorAttributeName] = UIColor.redColor()
                    
                    if actualGlyphRange.length > 1 {
                        nextGlyphLocation += actualGlyphRange.length
                    } else {
                        nextGlyphLocation += 1
                    }
                    
                    // glyph
                    let glyphAdvance = CTRunGetTypographicBounds(run, CFRangeMake(n, 1), nil, nil, nil)
                    let glyphImageBounds = CTRunGetImageBounds(run, nil, CFRangeMake(n, 1))
                    let glyphPosition = glyphPostions[n]
                    
                    if glyphImageBounds.width > 0 {
                        let origin = CGPoint(x: lineRect.minX + runPosition.x + glyphImageBounds.minX, y: lineRect.minY)
                        let size = CGSize(width: glyphImageBounds.width, height: lineRect.height)
                        
                        let typographicRect = CGRect(origin: CGPoint(x: lineRect.minX + glyphPosition.x, y: lineRect.minY), size: CGSize(width: CGFloat(glyphAdvance), height: lineRect.height))
                        
                        let unit = TextUnit(text: charaters, attributes: attributes, origin: origin, size: size, typographicRect: typographicRect, section: i, inSectionglyphIndex: n, inAllGlyphIndex: 0, constraintRect: constraintRect, usedSize: textSize, sectionRect: lineRect)
                        
                        infos.append(unit)
                        
                    }
                    
                    glyphLocation += 1
                }
            }
        }
        
        return infos
    }
}
