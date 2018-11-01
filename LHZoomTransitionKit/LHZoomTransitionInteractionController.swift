//
//  LHZoomTransitionInteractionController.swift
//  LHZoomTransitionKit
//
//  Created by 許立衡 on 2018/11/1.
//  Copyright © 2018 narrativesaw. All rights reserved.
//

import UIKit

public class LHZoomTransitionInteractionController: NSObject {

    private weak var transitionContext: UIViewControllerContextTransitioning?
    
    public func updateTransition(_ percentComplete: CGFloat) {
        guard let context = transitionContext else { return }
        context.updateInteractiveTransition(percentComplete)
    }
    
}

extension LHZoomTransitionInteractionController: UIViewControllerInteractiveTransitioning {
    
    public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
    }
    
}
