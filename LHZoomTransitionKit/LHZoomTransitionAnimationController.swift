//
//  LHZoomTransitionAnimationController.swift
//  Testing
//
//  Created by 許立衡 on 2018/11/1.
//  Copyright © 2018 narrativesaw. All rights reserved.
//

import UIKit
import LHConvenientMethods

public class LHZoomTransitionAnimationController: NSObject {
    
    public enum Operation {
        case present, dismiss
    }
    
    let duration: TimeInterval
    let operation: Operation
    let sourceTargetRect: CGRect
    let destinationTargetRect: CGRect
    public init(operation: Operation, duration: TimeInterval, sourceTargetRect: CGRect, destinationTargetRect: CGRect) {
        self.duration = 3
        self.operation = operation
        self.sourceTargetRect = sourceTargetRect
        self.destinationTargetRect = destinationTargetRect
    }

}

extension LHZoomTransitionAnimationController: UIViewControllerAnimatedTransitioning {
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        guard let toView = transitionContext.view(forKey: .to)  else { return }
        let containerView = transitionContext.containerView
        guard let toViewController = transitionContext.viewController(forKey: .to) else { return }
        
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.8)
        
        let toViewFinalFrame = transitionContext.finalFrame(for: toViewController)
        toView.frame = toViewFinalFrame
        containerView.addSubview(toView)
        let targetFinalFrame = toView.convert(destinationTargetRect, to: containerView)
        let targetInitialFrame = fromView.convert(sourceTargetRect, to: containerView)
        
        func prepareTargetSnapshot(_ snapshot: UIView) {
            containerView.addSubview(snapshot)
            snapshot.frame = targetInitialFrame
            animator.addAnimations {
                snapshot.frame = targetFinalFrame
            }
            animator.addCompletion { position in
                snapshot.removeFromSuperview()
            }
        }
        
        if let fromTargetSnapshot = fromView.resizableSnapshotView(from: sourceTargetRect, afterScreenUpdates: true, withCapInsets: .zero) {
            prepareTargetSnapshot(fromTargetSnapshot)
            animator.addAnimations {
                fromTargetSnapshot.alpha = 0
            }
        }
        if let toTargetSnapshot = toView.resizableSnapshotView(from: destinationTargetRect, afterScreenUpdates: true, withCapInsets: .zero) {
            prepareTargetSnapshot(toTargetSnapshot)
            toTargetSnapshot.alpha = 0
            animator.addAnimations {
                toTargetSnapshot.alpha = 1
            }
        }
        
        switch operation {
        case .present:
            toView.alpha = 0
            toView.transform = CGAffineTransform(fromRect: targetFinalFrame, toRect: targetInitialFrame)
            animator.addAnimations {
                toView.alpha = 1
                toView.transform = .identity
            }
        case .dismiss:
            containerView.insertSubview(toView, at: 0)
            animator.addAnimations {
                fromView.alpha = 0
                fromView.transform = CGAffineTransform(fromRect: targetInitialFrame, toRect: targetFinalFrame)
            }
        }
        
        animator.addCompletion { position in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        animator.startAnimation()
    }
    
}
