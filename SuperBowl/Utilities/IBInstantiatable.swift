//
//  IBInstantiatable.swift
//  SuperBowl
//
//  Created by mitsuyoshi.yamazaki on 2017/03/04.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

public protocol IBInstantiatable {
    static func instantiate() -> Self
}

public extension IBInstantiatable where Self: UIView {

    static func instantiate() -> Self {
        return self.instantiateFromNib()
    }

    static var nibName: String {
        return String.init(describing: Self.self)
    }
    
    static var nib: UINib {
        return UINib(nibName: self.nibName, bundle: nil)
    }
    
    static func instantiateFromNib() -> Self {
        return self.nib.instantiate(withOwner: nil, options: nil).first as! Self
    }
}

public extension IBInstantiatable where Self: UIViewController {
    
    static func instantiate() -> Self {
        return self.instantiateFromStoryboard()
    }
    
    static var storyboardName: String {
        return String.init(describing: Self.self)
    }
    
    static var storyboard: UIStoryboard {
        return UIStoryboard.init(name: self.storyboardName, bundle: nil)
    }
    
    static func instantiateFromStoryboard() -> Self {
        return self.storyboard.instantiateInitialViewController() as! Self
    }
}
