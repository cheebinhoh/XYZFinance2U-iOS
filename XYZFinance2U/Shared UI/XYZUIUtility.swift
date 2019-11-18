//
//  XYZUIUtility.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/17/19.
//  Copyright © 2019 CB Hoh. All rights reserved.
//

import UIKit

func createDownDisclosureIndicatorImage() -> UIImageView {
    
    let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 20, y: 20), size: CGSize(width: 18, height: 15)))
    imageView.image = UIImage(named:"down_disclosure_indicator")
    
    return imageView
}
