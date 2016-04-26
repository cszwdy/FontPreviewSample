//
//  FontMetrics.swift
//  FontPreview
//
//  Created by Emiaostein on 4/22/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import Foundation
import UIKit

struct FontMetric {
    
    let ascent: CGFloat
    let decent: CGFloat
    let lineCap: CGFloat
    let baselineOrigin: CGFloat
    let boundingBox: CGFloat
    let leftsideBearing: CGFloat
    let rightsideBearing: CGFloat
    let advanceWidth: CGFloat
    
    var lineHeight: CGFloat { return ascent + decent + lineCap }
}

