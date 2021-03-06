//
//  FavoritedUIButton.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 12/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

//This class implements a simple star-shaped favorite button.
//I could have probably done it in a simpler way by just using some icon,
//but I was afraid of scaling issues with non-vectorial graphics, and I 
//found a nice example of how to do this using the "PaintCode" application.
//I adapted that example to remove all animation-related code and leave a much
//simpler button that does the job
class FavoritedUIButton: UIButton {
    
    fileprivate lazy var starShape: CAShapeLayer = {
        var starFrame = self.bounds
        starFrame.size.width = starFrame.width/2.5
        starFrame.size.height = starFrame.height/2.5
        
        let shape = CAShapeLayer()
        shape.path = rescaleForFrame(path: Paths.star, frame: starFrame)
        shape.bounds = (shape.path?.boundingBox)!
        shape.fillColor = self.notFavoriteColor.cgColor
        shape.position = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
        shape.opacity = 0.5
        self.layer.addSublayer(shape)

        return shape
    }()
    
    let notFavoriteColor = UIColor.lightGray
    let favoriteColor = UIColor.red
    
    var isFavorite : Bool = false {
        didSet {
            if self.isFavorite {
                self.starShape.fillColor = self.favoriteColor.cgColor
                self.starShape.opacity = 1
            }
            else {
                self.starShape.fillColor = self.notFavoriteColor.cgColor
                self.starShape.opacity = 0.5
            }
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.isFavorite {
            self.starShape.fillColor = favoriteColor.cgColor
        }
        else {
            self.starShape.fillColor = notFavoriteColor.cgColor
        }
    }
    
}

//As the shape is "statically" designed in an external tool that creates code
//for it to be drawn, if you want to properly draw it at different sizes when
//putting it on the UI, you have to somehow rescale it, trying to preserve as much as
//possible its aspect ratio.
//This is what this function tries to achieve
private func rescaleForFrame(path: CGPath, frame: CGRect) -> CGPath {
    let boundingBox = path.boundingBox
    let boundingBoxAspectRatio = boundingBox.width/boundingBox.height
    let viewAspectRatio = frame.width/frame.height
    
    var scaleFactor: CGFloat = 1
    if (boundingBoxAspectRatio > viewAspectRatio) {
        scaleFactor = frame.width/boundingBox.width
    } else {
        scaleFactor = frame.height/boundingBox.height
    }
    
    var scaleTransform = CGAffineTransform.identity
    scaleTransform = scaleTransform.scaledBy(x: scaleFactor, y: scaleFactor)
    scaleTransform = scaleTransform.translatedBy(x: -boundingBox.minX, y: -boundingBox.minY)
    let scaledSize = boundingBox.size.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
    let centerOffset = CGSize(width: (frame.width-scaledSize.width)/(scaleFactor*2.0), height: (frame.height-scaledSize.height)/(scaleFactor*2.0))
    scaleTransform = scaleTransform.translatedBy(x: centerOffset.width, y: centerOffset.height)
    
    if let scaleTransform = path.copy(using: &scaleTransform) {
        return scaleTransform
    } else {
        return path
    }
}

//MARK:- CGPath generated by PaintCode
struct Paths {
    static var star: CGPath {
        let star = UIBezierPath()
        star.move(to: CGPoint(x: 112.79, y: 119))
        star.addCurve(to: CGPoint(x: 107.75, y: 122.6), controlPoint1: CGPoint(x: 113.41, y: 122.8), controlPoint2: CGPoint(x: 111.14, y: 124.42))
        star.addLine(to: CGPoint(x: 96.53, y: 116.58))
        star.addCurve(to: CGPoint(x: 84.14, y: 116.47), controlPoint1: CGPoint(x: 93.14, y: 114.76), controlPoint2: CGPoint(x: 87.56, y: 114.71))
        star.addLine(to: CGPoint(x: 72.82, y: 122.3))
        star.addCurve(to: CGPoint(x: 67.84, y: 118.62), controlPoint1: CGPoint(x: 69.4, y: 124.06), controlPoint2: CGPoint(x: 67.15, y: 122.41))
        star.addLine(to: CGPoint(x: 70.1, y: 106.09))
        star.addCurve(to: CGPoint(x: 66.37, y: 94.27), controlPoint1: CGPoint(x: 70.78, y: 102.3), controlPoint2: CGPoint(x: 69.1, y: 96.98))
        star.addLine(to: CGPoint(x: 57.33, y: 85.31))
        star.addCurve(to: CGPoint(x: 59.29, y: 79.43), controlPoint1: CGPoint(x: 54.6, y: 82.6), controlPoint2: CGPoint(x: 55.48, y: 79.95))
        star.addLine(to: CGPoint(x: 71.91, y: 77.71))
        star.addCurve(to: CGPoint(x: 81.99, y: 70.51), controlPoint1: CGPoint(x: 75.72, y: 77.19), controlPoint2: CGPoint(x: 80.26, y: 73.95))
        star.addLine(to: CGPoint(x: 87.72, y: 59.14))
        star.addCurve(to: CGPoint(x: 93.92, y: 59.2), controlPoint1: CGPoint(x: 89.46, y: 55.71), controlPoint2: CGPoint(x: 92.25, y: 55.73))
        star.addLine(to: CGPoint(x: 99.46, y: 70.66))
        star.addCurve(to: CGPoint(x: 109.42, y: 78.03), controlPoint1: CGPoint(x: 101.13, y: 74.13), controlPoint2: CGPoint(x: 105.62, y: 77.44))
        star.addLine(to: CGPoint(x: 122, y: 79.96))
        star.addCurve(to: CGPoint(x: 123.87, y: 85.87), controlPoint1: CGPoint(x: 125.81, y: 80.55), controlPoint2: CGPoint(x: 126.64, y: 83.21))
        star.addLine(to: CGPoint(x: 114.67, y: 94.68))
        star.addCurve(to: CGPoint(x: 110.75, y: 106.43), controlPoint1: CGPoint(x: 111.89, y: 97.34), controlPoint2: CGPoint(x: 110.13, y: 102.63))
        star.addLine(to: CGPoint(x: 112.79, y: 119))
        return star.cgPath
    }
}
