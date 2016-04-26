//
//  FontAttributes.swift
//  FontPreview
//
//  Created by Emiaostein on 4/22/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import Foundation
import UIKit

struct Color {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat
    var color: UIColor {
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

enum Ligature: Int {
    case Nont = 0
    case Default = 1
    case All = 2
}

struct TextAttributes {
    
    enum AttributeName {
        case FontName(String)
        case FontSize(CGFloat)
        case Alignment(NSTextAlignment)
        case lineHeightMultiple(CGFloat)
        case foregroundColor(Color)
        case backgroundColor(Color)
        case ligature(Ligature)
        case kerning(CGFloat)
        case baselineOffset(CGFloat)
        case obliqueness(CGFloat)
    }
    
    let fontName: String
    let fontSize: CGFloat
    let alignment: NSTextAlignment
    let lineHeightMultiple: CGFloat
    let foregroundColor: Color
    let backgroundColor: Color
    let ligature: Ligature
    let kerning: CGFloat
    let baselineOffset: CGFloat
    let obliqueness: CGFloat
    
    func updateWith(attributeNames: [AttributeName]) -> TextAttributes {
        
        guard attributeNames.count > 0 else { return self }
        
        var name = fontName
        var size = fontSize
        var ali = alignment
        var lineH = lineHeightMultiple
        var foreColor = foregroundColor
        var backColor = backgroundColor
        var liga = ligature
        var kern = kerning
        var offset = baselineOffset
        var obli = obliqueness
        
        for attriName in attributeNames {
            switch attriName {
            case .FontName(let n): name = n
            case .FontSize(let s): size = s
            case .Alignment(let a): ali = a
            case .lineHeightMultiple(let l): lineH = l
            case .foregroundColor(let c): foreColor = c
            case .backgroundColor(let c): backColor = c
            case .ligature(let l): liga = l
            case .kerning(let k): kern = k
            case .baselineOffset(let b): offset = b
            case .obliqueness(let o): obli = o
            }
        }
        
        return TextAttributes(
            fontName: name,
            fontSize: size,
            alignment: ali,
            lineHeightMultiple: lineH,
            foregroundColor: foreColor,
            backgroundColor: backColor,
            ligature: liga,
            kerning: kern,
            baselineOffset: offset,
            obliqueness: obli)
    }
}

extension TextAttributes {
    var font: UIFont? { return UIFont(name: fontName, size: fontSize) }
    var paragraphStyle: NSParagraphStyle {
        let para = NSMutableParagraphStyle()
        para.alignment = alignment
        para.lineHeightMultiple = lineHeightMultiple
        return para
    }
    
    var attributes: [String: AnyObject] {
        
        let attributes: [String: AnyObject] = [
            NSFontAttributeName: font!,
            NSParagraphStyleAttributeName: paragraphStyle,
            NSForegroundColorAttributeName: foregroundColor.color,
            NSBackgroundColorAttributeName: backgroundColor.color,
            NSLigatureAttributeName: ligature.rawValue,
            NSBaselineOffsetAttributeName: baselineOffset,
            NSKernAttributeName: kerning,
            NSObliquenessAttributeName: obliqueness
        ]
        
        return attributes
    }
    
    static var defaultAttributes: [String: AnyObject] {
        let attributes: [String: AnyObject] = [
            NSFontAttributeName: UIFont.systemFontOfSize(17.0),
            NSForegroundColorAttributeName: UIColor.blackColor(),
            NSBackgroundColorAttributeName: UIColor.clearColor(),
            NSLigatureAttributeName: Ligature.Default.rawValue,
            NSBaselineOffsetAttributeName: 0,
            NSKernAttributeName: 0,
            NSObliquenessAttributeName: 0
        ]
        
        return attributes
    }
}

/*
 
 let NSFontAttributeName: String
 let NSParagraphStyleAttributeName: String --
 let NSForegroundColorAttributeName: String
 let NSUnderlineStyleAttributeName: String  --
 let NSSuperscriptAttributeName: String --
 let NSBackgroundColorAttributeName: String
 let NSAttachmentAttributeName: String --
 let NSLigatureAttributeName: String
 let NSBaselineOffsetAttributeName: String
 let NSKernAttributeName: String
 let NSLinkAttributeName: String --
 let NSStrokeWidthAttributeName: String --
 let NSStrokeColorAttributeName: String --
 let NSUnderlineColorAttributeName: String --
 let NSStrikethroughStyleAttributeName: String --
 let NSStrikethroughColorAttributeName: String --
 let NSShadowAttributeName: String --
 let NSObliquenessAttributeName: String
 let NSExpansionAttributeName: String --
 let NSCursorAttributeName: String --
 let NSToolTipAttributeName: String --
 let NSMarkedClauseSegmentAttributeName: String --
 let NSWritingDirectionAttributeName: String --
 let NSVerticalGlyphFormAttributeName: String --
 let NSTextAlternativesAttributeName: String --
 
 */