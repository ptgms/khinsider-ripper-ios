//
//  TapToSearchView.swift
//  TapToSearchView
//
//  Created by ptgms on 02.08.21.
//

import UIKit

class TapToSearchView: UIView {
    @IBOutlet weak var arrowUp: UIImageView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position"
        animation.duration = 300
        animation.repeatCount = Float.infinity
        animation.isAdditive = true
        
        
        animation.values = (0..<300).map({ (side: Int) -> NSValue in
            let yPos = sin(CGFloat(side))

            let point = CGPoint(x: 0, y: yPos * 10)
        return NSValue(cgPoint: point)
        })
        arrowUp.layer.add(animation, forKey: "basic")
    }
    /*override func layoutSubviews() {
        super.layoutSubviews()
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position"
        animation.duration = 300
        animation.repeatCount = Float.infinity
        animation.isAdditive = true
        animation.values = {CGPoint(x:0, y:300), CGpoint(x:0, y:0)}
        animation.calculationMode = CAAnimationCalculationMode.cubic
        arrowUp.layer.add(animation,forKey: "basic")
    }*/
}
