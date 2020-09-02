import UIKit

/*
 OverlayViewStackController -> SheetableViewController -> Delegator  --weak--> Delegate(OverlayViewStackController)
 */

/// Protocol to store SheetScrollDelegator object.
public protocol SheetScrollTransitionDelegatable {
    var delegator: SheetScrollDelegator { get }
}


/// Object to connect SheetableViewController with Delegate(OverlayViewStackController). Catch UIScrollViewDelegate information from SheetableViewController and Delegate these to Delegate(OverlayViewStackController). To avoid cycled reference, store a delegate property as weak.
open class SheetScrollDelegator: SheetScrollTransitionable {
    weak var delegate: SheetScrollDelegate?
    
    public init() {
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.scrollViewWillBeginDragging(scrollView)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScroll(scrollView)
    }
    
    public func scrollView(_ scrollView: UIScrollView,
                    willEndScrollingWithVelocity velocity: CGPoint,
                    targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.scrollView(scrollView, willEndScrollingWithVelocity: velocity, targetContentOffset: targetContentOffset)
    }
}
