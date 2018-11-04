//
//  LHZoomTransitionAnimationController.swift
//  Testing
//
//  Created by 許立衡 on 2018/11/1.
//  Copyright © 2018 narrativesaw. All rights reserved.
//

import UIKit
import LHConvenientMethods

public protocol LHZoomTransitionTargetProviding: AnyObject {
    func targetView(for animationController: LHZoomTransitionAnimationController, operation: LHZoomTransitionAnimationController.Operation) -> UIView?
    func animationController(_ animationController: LHZoomTransitionAnimationController, willAnimate operation: LHZoomTransitionAnimationController.Operation)
    func animationController(_ animationController: LHZoomTransitionAnimationController, didAnimate operation: LHZoomTransitionAnimationController.Operation)
}
extension LHZoomTransitionTargetProviding {
    public func animationController(_ animationController: LHZoomTransitionAnimationController, willAnimate operation: LHZoomTransitionAnimationController.Operation) { }
    public func animationController(_ animationController: LHZoomTransitionAnimationController, didAnimate operation: LHZoomTransitionAnimationController.Operation) { }
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
        return transitionContext?.isAnimated == true ? duration : 0
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) else { return }
        guard let toVC = transitionContext.viewController(forKey: .to) else { return }
        let fromView: UIView = transitionContext.view(forKey: .from) ?? fromVC.view
        let toView: UIView = transitionContext.view(forKey: .to) ?? toVC.view
        let containerView = transitionContext.containerView
        
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), dampingRatio: dampingRatio)
        
        let operation: Operation = {
            if fromVC.presentedViewController === toVC {
                return .present
            } else if fromVC.presentingViewController === toVC {
                return .dismiss
            } else {
                fatalError("Unsupported operation")
            }
        }()
        
        let removingPresentingView = [.fullScreen, .currentContext].contains(transitionContext.presentationStyle)
        
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
        let toViewSnapshot = toView.snapshotView(afterScreenUpdates: true)
        let fromViewSnapshot = fromView.snapshotView(afterScreenUpdates: true)
        
        switch operation {
        case .present:
            if let toViewSnapshot = toViewSnapshot {
                toViewSnapshot.frame = toView.frame
                toViewSnapshot.alpha = 0
                containerView.addSubview(toViewSnapshot)
                animator.addAnimations {
                    toViewSnapshot.alpha = 1
                }
                animator.addCompletion { position in
                    toViewSnapshot.removeFromSuperview()
                }
            }
            toView.alpha = 0
            animator.addCompletion { position in
                toView.alpha = 1
            }
        case .dismiss:
            if let fromViewSnapshot = fromViewSnapshot {
                fromViewSnapshot.frame = fromView.frame
                containerView.addSubview(fromViewSnapshot)
                animator.addAnimations {
                    fromViewSnapshot.alpha = 0
                }
                animator.addCompletion { position in
                    fromViewSnapshot.removeFromSuperview()
                }
            }
            fromView.alpha = 0
        }
        
        if let sourceTargetView = source.targetView(for: self, operation: operation),
            let destinationTargetView = destination.targetView(for: self, operation: operation),
            let toViewSnapshot = toViewSnapshot, let fromViewSnapshot = fromViewSnapshot {
            
            let targetInitialFrame = sourceTargetView.convert(sourceTargetView.bounds, to: containerView)
            let targetFinalFrame = destinationTargetView.convert(destinationTargetView.bounds, to: containerView)
            let scale = CGScale(width: targetFinalFrame.width / targetInitialFrame.width, height: targetFinalFrame.height / targetInitialFrame.height)
            
            switch operation {
            case .present:
                let insets = UIEdgeInsets(containing: toView.frame, contained: targetFinalFrame)
                let toViewInitialFrame = targetInitialFrame.inset(by: insets.inverted() / scale)
                
                toViewSnapshot.frame = toViewInitialFrame
                animator.addAnimations {
                    toViewSnapshot.frame = toViewFinalFrame
                }
            case .dismiss:
                let insets = UIEdgeInsets(containing: fromView.frame, contained: targetInitialFrame)
                let fromViewFinalFrame = targetFinalFrame.inset(by: insets.inverted() * scale)
                
                animator.addAnimations {
                    fromViewSnapshot.frame = fromViewFinalFrame
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
        }
        
        
        
        animator.addCompletion { position in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self.source.animationController(self, didAnimate: operation)
            self.destination.animationController(self, didAnimate: operation)
        }
        source.animationController(self, willAnimate: operation)
        destination.animationController(self, willAnimate: operation)
        animator.startAnimation()
    }
    
}
