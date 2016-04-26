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
    private var infos: [NSAttributedString.TextUnit] {
        return attributedText?.generateTextUnitsIn(CGRect(x: 0, y: 0, width: bounds.width / 3, height: bounds.height)) ?? []
    }
    
    override func drawTextInRect(rect: CGRect) {
        
        
        if debug {
            super.drawTextInRect(CGRect(x: 0, y: 0, width: bounds.width / 3, height: bounds.height))
            drawTextUnit(infos)
        } else {
            super.drawTextInRect(CGRect(x: 0, y: 0, width: bounds.width / 3, height: bounds.height))
        }
    }
    
    func drawTextUnit(infos: [NSAttributedString.TextUnit]) {
        
        layer.sublayers?.forEach({ (alayer) in
            if let t = alayer as? TextLayer {
                t.removeFromSuperlayer()
            }
        })
        for info in infos {
            let rectanglePath = UIBezierPath(rect: info.usedRect)
            UIColor.blueColor().setStroke()
            rectanglePath.lineWidth = 0.5
            rectanglePath.stroke()
            
            let sectionPath = UIBezierPath(rect: info.sectionRect)
            UIColor.redColor().setStroke()
            sectionPath.lineWidth = 0.5
            sectionPath.stroke()
            
//            draw text
            let attributeText = NSAttributedString(string: info.text, attributes: info.attributes)
            attributeText.drawInRect(info.typographicRect)
            
            
            //text layer
            let textLayer = TextLayer()
//            textLayer.backgroundColor = UIColor.yellowColor().CGColor
            
            textLayer.contentsScale = UIScreen.mainScreen().scale
            textLayer.drawingRect = info.drawingRect
            textLayer.frame = info.frame
            textLayer.string = info.attributeString
//            textLayer.foregroundColor = UIColor.redColor().CGColor
            layer.addSublayer(textLayer)
            
        }
    }
}


extension NSAttributedString {
    
    struct TextUnit {
        let text: String
        let attributes: [String: AnyObject]?

        let origin: CGPoint  // used to view
        let size: CGSize  // used to view
        let typographicRect: CGRect  // used to view
        let section: Int
        let inSectionglyphIndex: Int
        let inAllGlyphIndex: Int
        let constraintRect: CGRect
        let usedSize: CGSize
        let sectionRect: CGRect
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
            let lineHeight = lineAscent + lineDecent + lineCap
            let lineSize = CGSize(width: CGFloat(width), height: lineHeight)
            let lineOrigin = CGPointApplyAffineTransform(CGPoint(x: lineBaseLineOrigin.x, y: lineBaseLineOrigin.y), CGAffineTransformConcat(CGAffineTransformMakeScale(1, -1), CGAffineTransformMakeTranslation(0, bounds.height + 0.5 * (bounds.height - textSize.height) - lineAscent)))
            
            // Line Rect
            let lineRect = CGRect(origin: lineOrigin, size: lineSize)
            
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

































extension NSAttributedString {
    
    func textInfosIn(constraintSize: CGSize) -> [TextInfo] {
        
        let c1 = UIColor.redColor()
        let c2 = UIColor.blackColor()
        
        // AttributeString
        /*
         let bounding =  boundingRectWithSize(constraintSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
         let info1 = TextInfo(origin: bounding.origin, size: bounding.size)
         */
        
        // NSLayoutNamanager
        let storage = NSTextStorage(attributedString: self)
        let container = NSTextContainer(size: constraintSize)
        let manager = NSLayoutManager()
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        container.lineFragmentPadding = 0
        
//        let useRect = manager.usedRectForTextContainer(container)
//        let yOffset = 0.5 * (constraintSize.height - useRect.height)
//        let arect = useRect
//        let info1 = TextInfo(origin: CGPoint(x: arect.minX, y: arect.minY + yOffset), size: arect.size)
        
        var infos = [TextInfo]()
        
        let constrainTextInfo = TextInfo(origin: CGPoint.zero, size: constraintSize, color: c1)
        infos.append(constrainTextInfo)
//        
//        let usedRectTextInfo = TextInfo(origin: useRect.origin, size: useRect.size)
//        infos.append(usedRectTextInfo)
        
        /* Enclosed Rect
        manager.enumerateEnclosingRectsForGlyphRange(NSMakeRange(0, self.length), withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0), inTextContainer: container) { (closedRect, nil) in
            
            let rect = closedRect
            let info = TextInfo(origin: CGPoint(x: rect.minX, y: rect.minY + yOffset), size: rect.size)
            infos.append(info)
        }
        */
        
        /* Line Fragment
        manager.enumerateLineFragmentsForGlyphRange(NSMakeRange(0, length)) { (lineRect, usedRect, container, glyphRange, nil) in
            
            let rect = lineRect
            let info = TextInfo(origin: CGPoint(x: rect.minX, y: rect.minY + yOffset), size: rect.size)
            infos.append(info)
        }
         */

        // CTLine, CTFramer, CTRun, CTFramersetter
        let rect = CGRect(origin: CGPoint.zero, size: constraintSize)
        let path = CGPathCreateWithRect(rect, nil)
        let frameSetter = CTFramesetterCreateWithAttributedString(self)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, 0), nil, constraintSize, nil)
        
        // Framer
        let boundingOffset = CGPoint(x: 0.5 * (constraintSize.width - size.width), y: 0.5 * (constraintSize.height - size.height))
        
        let boundsRectTextInfo = TextInfo(origin: boundingOffset, size: size, color: c2)
        infos.append(boundsRectTextInfo)
        
        // Lines
        let key = kCTFrameProgressionAttributeName
        let value = NSNumber(unsignedInt: CTFrameProgression.TopToBottom.rawValue)
        
        var keys = [unsafeAddressOf(key)]
        var values = [unsafeAddressOf(value)]
        
        let dic = CFDictionaryCreate(kCFAllocatorDefault, &keys, &values, 1, nil, nil)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, dic)
        let lines = CTFrameGetLines(frame) // 0 - 1 - 2
        let lineCount = CFArrayGetCount(lines)
        var lineOrigins = Array(count: lineCount, repeatedValue: CGPoint.zero) // 0 - 1 - 2
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &lineOrigins)
        
        for i in 0..<lineCount {
            // Line
            let lineOrigin = lineOrigins[i] // fliped line baseline origin
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, i), CTLine.self)
//            let imagebounds = CTLineGetImageBounds(line, nil)
            
            var a: CGFloat = 0
            var d: CGFloat = 0
            var l: CGFloat = 0
            let width = CTLineGetTypographicBounds(line, &a, &d, &l)
            let lh = a + d + l
            let typobounds = CGRect(origin: CGPoint.zero, size: CGSize(width: CGFloat(width), height: lh))
            
            
            let bounds = typobounds
            let origin = CGPointApplyAffineTransform(CGPoint(x: lineOrigin.x, y: lineOrigin.y), CGAffineTransformConcat(CGAffineTransformMakeScale(1, -1), CGAffineTransformMakeTranslation(0, constraintSize.height + boundingOffset.y - a)))
            
            let size = CGSize(width: bounds.width, height: bounds.height)
            
            let lineglycount = CTLineGetGlyphCount(line)
            let stringRange = CTLineGetStringRange(line)
            if lineglycount > 0 && (self.string as NSString).substringWithRange(NSMakeRange(stringRange.location, stringRange.length)) != "\n" {
                if lineglycount > 0 {
                    let lineInfo = TextInfo(origin: origin, size: size, color: c1)
                    infos.append(lineInfo)
                }
            }
            
            // Runs
            let runs = CTLineGetGlyphRuns(line)
            let runsCount = CFArrayGetCount(runs)
            
            
            for j in 0..<runsCount {
                // Run
                let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, j), CTRun.self)
                let count = CTRunGetGlyphCount(run)
                var positions = Array(count: count, repeatedValue: CGPoint.zero)
                CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
                var advances = Array(count: count, repeatedValue: CGSize.zero)
                CTRunGetAdvances(run, CFRangeMake(0, 0), &advances)
                
                var ascent: CGFloat = 0.0
                var decent: CGFloat = 0.0
                var leading: CGFloat = 0.0
                CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &decent, &leading)
//                let runHeight = ascent + decent + leading
                
                let firtRunPosition = positions[0]
                
                // glyph
                for c in 0..<count {
                    
                    let imageBounds = CTRunGetImageBounds(run, nil, CFRangeMake(c, 1))
                    
                    let position = positions[c] // glyph position
                    let advance = advances[c]
                    let origin = CGPointApplyAffineTransform(CGPoint(x: lineOrigin.x, y: lineOrigin.y), CGAffineTransformConcat(CGAffineTransformMakeScale(1, -1), CGAffineTransformMakeTranslation(0,boundingOffset.y + constraintSize.height - a))) // line position
                    
                    if imageBounds.width > 0 {
                        print("position = \(position), imagebounds = \(imageBounds)")
                        let realPosition = CGPoint(x: firtRunPosition.x + imageBounds.minX, y: position.y)
                        let info = generateInfoWith(CGPoint.zero, lineOffset: origin, glyphPosition: realPosition, glyphSize: CGSize(width: imageBounds.width, height: size.height))
                        infos.append(info)
                    } else {
                        print("aaaa")
//                        let info = generateInfoWith(CGPoint.zero, lineOffset: origin, glyphPosition: position, glyphSize: CGSize(width: imageBounds.width, height: size.height))
//                        infos.append(info)
                    }
                    
                }
            }
        }
        return infos
    }
    
    func generateInfoWith(boundingOffset: CGPoint, lineOffset: CGPoint, glyphPosition: CGPoint, glyphSize: CGSize) -> TextInfo {
        
        let offset = CGPoint(x:  boundingOffset.x + lineOffset.x, y: boundingOffset.y + lineOffset.y)
        let position = CGPoint(x: glyphPosition.x + offset.x, y: glyphPosition.y + offset.y)
        let info = TextInfo(origin: position, size: glyphSize, color: UIColor.blueColor())
        return info
    }
    
}
