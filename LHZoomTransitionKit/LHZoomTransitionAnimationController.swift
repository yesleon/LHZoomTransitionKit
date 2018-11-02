//
//  LHZoomTransitionAnimationController.swift
//  Testing
//
//  Created by 許立衡 on 2018/11/1.
//  Copyright © 2018 narrativesaw. All rights reserved.
//

import UIKit
import LHConvenientMethods

public protocol LHZoomTransitionTargetProviding {
    func targetView(for animationController: LHZoomTransitionAnimationController, operation: LHZoomTransitionAnimationController.Operation) -> UIView?
    func animationControllerWillAnimate(_ animationController: LHZoomTransitionAnimationController)
    func animationControllerDidAnimate(_ animationController: LHZoomTransitionAnimationController)
}
extension LHZoomTransitionTargetProviding {
    public func animationControllerWillAnimate(_ animationController: LHZoomTransitionAnimationController) { }
    public func animationControllerDidAnimate(_ animationController: LHZoomTransitionAnimationController) { }
}

public class LHZoomTransitionAnimationController: NSObject {
    
    public enum Operation {
        case present, dismiss
    }
    
    let duration: TimeInterval
    let dampingRatio: CGFloat
    public let source: LHZoomTransitionTargetProviding
    public let destination: LHZoomTransitionTargetProviding
    
    public init(duration: TimeInterval, dampingRatio: CGFloat, source: LHZoomTransitionTargetProviding, destination: LHZoomTransitionTargetProviding) {
        self.duration = duration
        self.dampingRatio = dampingRatio
        self.source = source
        self.destination = destination
    }

}

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
        
        let operation: Operation
        
        let removingPresentingView: Bool
        if fromVC.presentedViewController === toVC {
            operation = .present
            removingPresentingView = [UIModalPresentationStyle.fullScreen, .currentContext].contains(toVC.modalPresentationStyle)
        } else if fromVC.presentingViewController === toVC {
            operation = .dismiss
            removingPresentingView = [UIModalPresentationStyle.fullScreen, .currentContext].contains(fromVC.modalPresentationStyle)
        } else {
            return
        }
        
        let toViewFinalFrame = transitionContext.finalFrame(for: toVC)
        switch operation {
        case .present:
            toView.frame = toViewFinalFrame
            containerView.addSubview(toView)
            toView.layoutIfNeeded()
        case .dismiss:
            if removingPresentingView {
                containerView.addSubview(toView)
            }
        }
        
        guard let sourceTargetView = source.targetView(for: self, operation: operation) else { return }
        guard let destinationTargetView = destination.targetView(for: self, operation: operation) else { return }
        
        let targetInitialFrame = sourceTargetView.convert(sourceTargetView.bounds, to: containerView)
        let targetFinalFrame = destinationTargetView.convert(destinationTargetView.bounds, to: containerView)
        
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
        
        if let fromTargetSnapshot = sourceTargetView.snapshotView(afterScreenUpdates: true) {
            prepareTargetSnapshot(fromTargetSnapshot)
        }
        
        if let toTargetSnapshot = destinationTargetView.snapshotView(afterScreenUpdates: true) {
            prepareTargetSnapshot(toTargetSnapshot)
        }
        
        animator.addCompletion { position in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self.source.animationControllerDidAnimate(self)
            self.destination.animationControllerDidAnimate(self)
        }
        source.animationControllerWillAnimate(self)
        destination.animationControllerWillAnimate(self)
        animator.startAnimation()
    }
    
}
