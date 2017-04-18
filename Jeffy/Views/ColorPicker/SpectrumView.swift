//
//  SpectrumView.swift
//  LumenCamera
//
//  Created by Mohssen Fathi on 6/30/16.
//  Copyright © 2016 mohssenfathi. All rights reserved.
//

import UIKit

class SpectrumView: UIView {
    
    var hueOnly: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        let size: CGFloat = 1.0
        let width : CGFloat = rect.size.width
        let height: CGFloat = rect.size.height
        
        let context = UIGraphicsGetCurrentContext()
        
        for i in stride(from: 0, to: width, by: size) {
            
            let h = i / width
            
            for j in stride(from: 0, to: height, by: size) {
                
                let s = j < (height / 2) ? 1 : (height - j) / (height / 2)
                let b = j < (height / 2) ? j / (height / 2) : 1
                
                var color: UIColor!
                if hueOnly {
                    color = UIColor(hue: h, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                }
                else {
                    color = UIColor(hue: h, saturation: s, brightness: b, alpha: 1.0)
                }
                
                context?.setFillColor(color.cgColor)
                context?.fill(CGRect(x: i, y: j, width: size, height: size))
                
            }
        }
        
    }
    
    /*  point is normalized  */
    func color(_ point: CGPoint) -> UIColor {
        
        let width  = frame.size.width
        let height = frame.size.height
        let x = point.x * width
        let y = point.y * height
        
        let h = x / width
        let s = point.y < (0.5) ? 1 : (height - y) / (height / 2)
        let b = point.y < (0.5) ? y / (height / 2) : 1
        
        
        if hueOnly {
            return UIColor(hue: h, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }
        else {
            return UIColor(hue: h, saturation: s, brightness: b, alpha: 1.0)
        }
        
    }
    
}
