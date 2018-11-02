//
//  LHZoomSegue.swift
//  LHZoomTransitionKit
//
//  Created by 許立衡 on 2018/11/2.
//  Copyright © 2018 narrativesaw. All rights reserved.
//


public class LHZoomSegue: UIStoryboardSegue {
    
    public var duration: TimeInterval = 0.4
    public var dampingRatio: CGFloat = 1
    public weak var sourceTargetProvider: LHZoomTransitionTargetProviding?
    public weak var destinationTargetProvider: LHZoomTransitionTargetProviding?
    
    private func makeAnimationController() -> UIViewControllerAnimatedTransitioning? {
        if let sourceTargetProvider = sourceTargetProvider, let destinationTargetProvider = destinationTargetProvider {
            return LHZoomTransitionAnimationController(duration: duration, dampingRatio: dampingRatio, source: sourceTargetProvider, destination: destinationTargetProvider)
        }
        return nil
    }
    
}

extension LHZoomSegue: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return makeAnimationController()
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return makeAnimationController()
    }
    
}

public class LHZoomInSegue: LHZoomSegue {
    
    public override func perform() {
        destination.transitioningDelegate = self
        source.present(destination, animated: true, completion: nil)
    }
    
}

public class LHZoomOutSegue: LHZoomSegue {
    
    public override func perform() {
        source.transitioningDelegate = self
        destination.dismiss(animated: true, completion: nil)
    }
    
}
