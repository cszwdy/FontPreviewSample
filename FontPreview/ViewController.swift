//
//  ViewController.swift
//  FontPreview
//
//  Created by Emiaostein on 4/22/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var label: MetricLabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        setupText()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func setup() {

        let text = attributeText(4, fontName: "Zapfino", fontSize: 18, kern: 20)
        label.attributedText = text
        label.debug = true
        label.hidden = true
    }
    
    
    func setupText() {
        let text = attributeText(4, fontName: "Zapfino", fontSize: 18, kern: 20)
        
        let constraintSize = CGSize(width: 414, height: 1000)
        let bounds = CGRect(origin: CGPoint.zero, size: constraintSize)
        let pathRect = bounds
        let frameSetter = CTFramesetterCreateWithAttributedString(text)
        let textSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, 0), nil, constraintSize, nil)
        
        let l = UILabel(frame: CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height))
        l.numberOfLines = 0
        l.backgroundColor = UIColor.yellowColor()
        l.attributedText = text
        view.addSubview(l)
        
        print(l.textRectForBounds(l.bounds, limitedToNumberOfLines: 0))
        
//         textlayer
        let infos = text.generateTextUnitsIn(CGRect(origin: CGPoint(x: 0, y: 20), size: textSize))
        for info in infos {
            //text layer
            let textLayer = TextLayer()
            textLayer.contentsScale = UIScreen.mainScreen().scale
            textLayer.drawingRect = info.drawingRect
            textLayer.frame = info.frame
            textLayer.string = info.attributeString
            view.layer.addSublayer(textLayer)
        }
        
    }
    
    
    
    
    func attributeText(index: Int, fontName: String, fontSize: CGFloat, kern: CGFloat ) -> NSAttributedString {
        
        let attributes = TextAttributes(
            fontName: fontName,
            fontSize: fontSize,
            alignment: .Right,
            lineHeightMultiple: 1.4,
            foregroundColor: Color(r: 0, g: 0, b: 0, a: 1),
            backgroundColor: Color(r: 1, g: 1, b: 1, a: 0),
            ligature: .Default,
            kerning: kern, baselineOffset: 0, obliqueness: 0
        )
        let text: String
        switch index {
        case 0:
            text = "我叫陈星宇";
        case 1:
            text = "I'm Emiaostein";
        case 2:
            text = "我叫陈星宇，Emiaostein";
        case 3:
            text = "我叫陈星宇\n今年二十六";
        case 4:
            text = "I'm Emiaostein\nI'm twenty six";
        default:
            text = "没有对应的文字";
        }
        
        return NSAttributedString(string: text, attributes: attributes.attributes)
    }
    
}

