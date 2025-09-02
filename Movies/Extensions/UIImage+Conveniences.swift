//
//  UIImage+Conveniences.swift
//  Movies
//
//  Created by Rod Brown on 31/01/2016.
//  Copyright © 2016 Rod Brown. All rights reserved.
//

import UIKit

extension UIImage {
    
    func drawAspect(filling rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.saveGState()
        
        let initialSize = self.size
        let size = rect.size
        
        // calculate rect
        let imageAspect = initialSize.width / initialSize.height
        let drawRect: CGRect
        if size.width / imageAspect >= size.height {
            drawRect = CGRect(x: 0.0, y: (size.height - size.width / imageAspect) / 2.0, width: size.width, height: size.width / imageAspect)
        } else {
            drawRect = CGRect(x: (size.width - size.height * imageAspect) / 2.0, y: 0.0, width: size.height * imageAspect, height: size.height)
        }
        
        context.clip(to: rect)
        draw(in: drawRect)
        context.restoreGState()
    }
    
}
