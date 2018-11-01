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
    
    public typealias RectCalculator = () -> CGRect
    
    let duration: TimeInterval
    let operation: Operation
    let dampingRatio: CGFloat
    let sourceTargetRect: RectCalculator
    let destinationTargetRect: RectCalculator
    
    public init(operation: Operation, duration: TimeInterval, dampingRatio: CGFloat, sourceTargetRect: @escaping RectCalculator, destinationTargetRect: @escaping RectCalculator) {
        self.duration = duration
        self.operation = operation
        self.dampingRatio = dampingRatio
        self.sourceTargetRect = sourceTargetRect
        self.destinationTargetRect = destinationTargetRect
    }

}

extension UIEdgeInsets {
    init(containing: CGRect, contained: CGRect) {
        self.init(top: contained.minY - containing.minY,
                  left: contained.minX - containing.minX,
                  bottom: containing.maxY - contained.maxY,
                  right: containing.maxX - contained.maxX)
    }
    static func *(insets: UIEdgeInsets, scale: CGScale) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: insets.top * scale.height, left: insets.left * scale.width, bottom: insets.bottom * scale.height, right: insets.right * scale.width)
    }
    static func /(insets: UIEdgeInsets, scale: CGScale) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: insets.top / scale.height, left: insets.left / scale.width, bottom: insets.bottom / scale.height, right: insets.right / scale.width)
    }
    func inverted() -> UIEdgeInsets {
        return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
    }
}

typealias CGScale = CGSize

extension LHZoomTransitionAnimationController: UIViewControllerAnimatedTransitioning {
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) else { return }
        guard let toVC = transitionContext.viewController(forKey: .to) else { return }
        let fromView: UIView = transitionContext.view(forKey: .from) ?? fromVC.view
        let toView: UIView = transitionContext.view(forKey: .to) ?? toVC.view
        let containerView = transitionContext.containerView
        
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: dampingRatio)
        
        let toViewFinalFrame = transitionContext.finalFrame(for: toVC)
        if operation == .present {
            toView.frame = toViewFinalFrame
            containerView.addSubview(toView)
            toView.layoutIfNeeded()
        }
        
        let targetInitialFrame = fromVC.view.convert(sourceTargetRect(), to: containerView)
        let targetFinalFrame = toVC.view.convert(destinationTargetRect(), to: containerView)
        
        let scale = CGScale(width: targetFinalFrame.width / targetInitialFrame.width, height: targetFinalFrame.height / targetInitialFrame.height)
        switch operation {
        case .present:
            let toViewSnapshot = toView.snapshotView(afterScreenUpdates: true)!
            let insets = UIEdgeInsets(containing: toView.frame, contained: targetFinalFrame)
            let toViewInitialFrame = targetInitialFrame.inset(by: insets.inverted() / scale)
            
            containerView.addSubview(toViewSnapshot)
            toViewSnapshot.frame = toViewInitialFrame
            toView.alpha = 0
            animator.addAnimations {
                toViewSnapshot.frame = toViewFinalFrame
            }
            animator.addCompletion { position in
                toView.alpha = 1
                toViewSnapshot.removeFromSuperview()
            }
            toViewSnapshot.alpha = 0
            animator.addAnimations {
                toViewSnapshot.alpha = 1
            }
        case .dismiss:
            let fromViewSnapshot = fromView.snapshotView(afterScreenUpdates: true)!
            let insets = UIEdgeInsets(containing: fromView.frame, contained: targetInitialFrame)
            let fromViewFinalFrame = targetFinalFrame.inset(by: insets.inverted() * scale)
            
            containerView.addSubview(fromViewSnapshot)
            fromViewSnapshot.frame = fromView.frame
            fromView.removeFromSuperview()
            animator.addAnimations {
                fromViewSnapshot.frame = fromViewFinalFrame
            }
            animator.addCompletion { position in
                fromViewSnapshot.removeFromSuperview()
            }
            animator.addAnimations {
                fromViewSnapshot.alpha = 0
            }
        }
        
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
        
        if let fromTargetSnapshot = fromVC.view.resizableSnapshotView(from: sourceTargetRect(), afterScreenUpdates: true, withCapInsets: .zero) {
            prepareTargetSnapshot(fromTargetSnapshot)
        }
        
        if let toTargetSnapshot = toVC.view.resizableSnapshotView(from: destinationTargetRect(), afterScreenUpdates: true, withCapInsets: .zero) {
            prepareTargetSnapshot(toTargetSnapshot)
        }
        
        animator.addCompletion { position in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        animator.startAnimation()
    }
    
}
