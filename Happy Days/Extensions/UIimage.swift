//
//  UIimage.swift
//  Happy Days
//
//  Created by Артур Азаров on 15.02.2018.
//  Copyright © 2018 Артур Азаров. All rights reserved.
//

import UIKit

extension UIImage {
    func resize(to width: CGFloat) -> UIImage? {
        let scale = width / self.size.width
        let height = self.size.height * scale
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height) , false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
