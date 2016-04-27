//
//  ViewController.swift
//  FontPreview
//
//  Created by Emiaostein on 4/22/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import UIKit

extension NSAttributedString {
    
    struct Frame {
        let constraint: CGRect
        let origin: CGPoint  // coordinate to Constraint.
        let size: CGSize
        
        var inConstraintFrame: CGRect { return CGRect(origin: origin, size: size) }
        
    }
    
    struct Line {
        let frame: Frame
        let baselineOrigin: CGPoint // coordinate to Frame
        let advance: CGFloat
        let ascent: CGFloat         // coordinate to baselineOrigin
        let decent: CGFloat         // coordinate to baselineOrigin
        let lineCap: CGFloat        // coordinate to baselineOrigin
        
//        var lineHeight: CGFloat { return ascent + decent + lineCap }
        var origin: CGPoint { return CGPoint(x: baselineOrigin.x, y: baselineOrigin.y - ascent) }
        var size: CGSize { return CGSize(width: advance, height: ascent + decent + lineCap) }
        var inConstraintFrame: CGRect { return CGRect(x: origin.x + frame.inConstraintFrame.minX, y: origin.y + frame.inConstraintFrame.minY, width: size.width, height: size.height)}
    }
    
    struct Glyph {
        let text: String
        let attributes: [String: AnyObject]?
        
        let line: Line
        let frame: Frame
        let origin: CGPoint     // image bounds origin. coordinate to Line
        let size: CGSize        // image bounds size.
        let glyphRect: CGRect   //typographic rect. coordinate to Frame.
        
        // caculate propeties
        var attributeText: NSAttributedString { return NSAttributedString(string: text, attributes: attributes) }
        var inConstraintFrame: CGRect { return CGRect(origin: CGPoint(x: origin.x + line.inConstraintFrame.minX, y: origin.y + line.inConstraintFrame.minY), size: size) }
        var inConstraintDrawRect: CGRect { return CGRect(x: glyphRect.minX + frame.inConstraintFrame.minX, y: glyphRect.minY + frame.inConstraintFrame.minY, width: glyphRect.width, height: glyphRect.height) }
        var inImageBoundsDrawRect: CGRect { return CGRect(x: inConstraintDrawRect.minX - inConstraintFrame.minX, y: inConstraintDrawRect.minY - inConstraintDrawRect.minY, width: glyphRect.width, height: glyphRect.height) }
    }
    
    func generateElementsWith(constraintRect: CGRect) -> ([Glyph], [Line], Frame) {
        
        var elementGlyphs = [Glyph]()
        var elementLines = [Line]()
        let elementFrame: Frame!
        
        let constraintBounds = CGRect(origin: CGPoint.zero, size: constraintRect.size)
        
        // Frame
        let frameSetter = CTFramesetterCreateWithAttributedString(self)
        let textSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, 0), nil, constraintBounds.size, nil)  // enclosed texts rect
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: textSize)).CGPath, nil)
        
        elementFrame = Frame(constraint: constraintRect, origin: CGPoint(x: 0, y: 0), size: textSize)
        
        // Lines
        let lines = CTFrameGetLines(frame)
        let lineCount = CFArrayGetCount(lines)
        var lineOrigins = Array(count: lineCount, repeatedValue: CGPoint.zero)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &lineOrigins)  // bottom to top coordination's line baseline origin. coordinate to Frame.
        
        for l in 0..<lineCount {
            // Line
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, l), CTLine.self)
            let lineOrigin = lineOrigins[l]
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var lineCap: CGFloat = 0
            let advance = CTLineGetTypographicBounds(line, &ascent, &descent, &lineCap)
            let baselineOrigin = CGPointApplyAffineTransform(lineOrigin, CGAffineTransformConcat(CGAffineTransformMakeScale(1, -1), CGAffineTransformMakeTranslation(0, textSize.height))) // top to bottom coordinaition's line baseline origin
            
            // ElementLine
            let elementLine = Line(frame: elementFrame, baselineOrigin: baselineOrigin, advance: CGFloat(advance), ascent: ascent, decent: descent, lineCap: lineCap)
            elementLines.append(elementLine)
            
            // Runs
            let runs = CTLineGetGlyphRuns(line)
            let runCount = CFArrayGetCount(runs)
            
            for r in 0..<runCount {
                // Run
                let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, r), CTRun.self)
                let stringRange = CTRunGetStringRange(run)
                
                // Glyphs
                let runGlyphCount = CTRunGetGlyphCount(run)
                var runGlyphs = Array(count: runGlyphCount, repeatedValue: CGGlyph())
                CTRunGetGlyphs(run, CFRangeMake(0, 0), &runGlyphs)
                var runGlyphPositions = Array(count: runGlyphCount, repeatedValue: CGPoint.zero)
                CTRunGetPositions(run, CFRangeMake(0, 0), &runGlyphPositions)
                var stringIdicates = Array(count: runGlyphCount, repeatedValue: 0)
                CTRunGetStringIndices(run, CFRangeMake(0, 0), &stringIdicates)
                
                print("stringRange = \(stringRange)\nstringIdicates = \(stringIdicates)")
                
                var restCharacters = stringRange.length
                for g in 0..<runGlyphCount {
                    // Glyph
                    let glyph = runGlyphs[g]
                    let glyphPosition = runGlyphPositions[g] // coordinate to Line Origin (not baseline origin)
                    var gAscent: CGFloat = 0
                    var gDesent: CGFloat = 0
                    var gLeading: CGFloat = 0
                    let width = CTRunGetTypographicBounds(run, CFRangeMake(g, 1), &gAscent, &gDesent, &gLeading)
                    
                    // ElementGlyph
                    // TODO: origin, Size -- EMIAOSTEIN, 27/04/16, 14:51
                    let gOrigin = CGPoint(x: glyphPosition.x, y: glyphPosition.y + baselineOrigin.y - ascent)
                    
                    let length: Int = {
                        if runGlyphCount <= 1 {
                            return restCharacters
                        } else {
                            if g < runGlyphCount - 1 {
                                let l = stringIdicates[g + 1] - stringIdicates[g]
                                restCharacters -= l
                                return l
                            } else {
                                return restCharacters
                            }
                        }
                    }()
                    let t = (string as NSString).substringWithRange(NSMakeRange(stringIdicates[g], length))
                    let a = attributesAtIndex(stringIdicates[g], effectiveRange: nil)
                    
                    let elementGlyph = Glyph(text: t, attributes: a, line: elementLine, frame: elementFrame, origin: CGPoint.zero, size: CGSize.zero, glyphRect: CGRect(origin: gOrigin, size: CGSize(width: CGFloat(width), height: gAscent + gDesent + gLeading)))
                    elementGlyphs.append(elementGlyph)
                }
            }
        }
        
        return (elementGlyphs, elementLines, elementFrame)
    }
    
    
}

class ViewController: UIViewController {

    @IBOutlet weak var label: MetricLabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setup()
//        setupText()
        
        began()
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func began() {
        
        let fontName = "Zapfino"
        let fontSize: CGFloat = 30
        let kern: CGFloat = 0
        let text = attributeText(7, fontName: fontName, fontSize: fontSize, kern: kern)
        
        // text bounds
        let textSize: CGSize = {
           
            let constraintSize = CGSize(width: 320.0, height: CGFloat.max)
            let frameSetter = CTFramesetterCreateWithAttributedString(text)
            let textSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, 0), nil, constraintSize, nil)
            return textSize
        }()
        
        // element
        let elements = text.generateElementsWith(CGRect(origin: CGPoint.zero, size: textSize))
        
        // constraint view
        let constraintView = ConstraintView(frame: CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height))
        constraintView.center = CGPoint(x: 160, y: 568 / 2)
        constraintView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        constraintView.elements = elements
        
        view.addSubview(constraintView)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /*
     RTWSLangSongG0v1-Regular
     RTWSBanHeiG0v1-Regular
     MFDianHei_Noncommercial-Regular
     MFMiaoMiao_Noncommercial-Regular
     MFYueHei_Noncommercial-Regular
     FZZHJW--GB1-0
     FZYTJW--GB1-0
     JYouXian
     
     "Times New Roman", 
     "American Typewriter", 
     "Snell Roundhand", 
     "Chalkduster"
     */
    
    func setup() {

        let text = attributeText(3, fontName: "Zapfino", fontSize: 25, kern: 0)
        label.attributedText = text
        label.debug = true
//        label.hidden = true
    }
    
    
    func setupText() {
        let text = attributeText(1, fontName: "Zapfino", fontSize: 15, kern: 0)
        
        let constraintSize = CGSize(width: 100, height: 1000)
//        let bounds = CGRect(origin: CGPoint.zero, size: constraintSize)
//        let pathRect = bounds
        let frameSetter = CTFramesetterCreateWithAttributedString(text)
        let textSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, 0), nil, constraintSize, nil)
        
        let l = UILabel(frame: CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height))
        l.numberOfLines = 0
        
        l.backgroundColor = UIColor.yellowColor()
        l.attributedText = text
        view.addSubview(l)
        
        print(l.textRectForBounds(l.bounds, limitedToNumberOfLines: 0))
        
//         textlayer
//        let infos = text.generateTextUnitsIn(CGRect(origin: CGPoint(x: 0, y: 0), size: textSize))
//        for info in infos {
//            //text layer
//            let textLayer = TextLayer()
//            textLayer.contentsScale = UIScreen.mainScreen().scale
//            textLayer.drawingRect = info.drawingRect
//            textLayer.frame = info.frame
//            textLayer.string = info.attributeString
//            view.layer.addSublayer(textLayer)
//        }
        
    }
    
    
    
    
    func attributeText(index: Int, fontName: String, fontSize: CGFloat, kern: CGFloat ) -> NSAttributedString {
        
        let attributes = TextAttributes(
            fontName: fontName,
            fontSize: fontSize,
            alignment: .Left,
            lineHeightMultiple: 1,
            foregroundColor: Color(r: 0, g: 0, b: 0, a: 1),
            backgroundColor: Color(r: 1, g: 1, b: 1, a: 0),
            ligature: .Default,
            kerning: kern, baselineOffset: 0, obliqueness: 0
        )
        let text: String
        switch index {
        case 0:
            text = "I'mf       \nEmiaostein";
        case 1:
            text = "I'm Emiaostein\nI'm twenty six.";
        case 2:
            text = "I'm Emiaostein \nI'm twenty six.";
        case 3:
            text = "f我叫陈星宇今年二十六";
        case 4:
            text = "I'm Emiaostein\nI'm twenty six";
        case 5:
            text = "for "
        case 6:
            text = "f"
        case 7:
            text = "我🇨🇳ffine-1ff😄\nLine-2-h\nLine-3-3-3-3"
        default:
            text = "没有对应的文字";
        }
        
        return NSAttributedString(string: text, attributes: attributes.attributes)
    }
    
}

