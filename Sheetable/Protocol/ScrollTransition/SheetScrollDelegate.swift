import UIKit

/// Protocol to delegate UIScrollViewDelegate information to OverlayViewStackController
protocol SheetScrollDelegate: class {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollView(_ scrollView: UIScrollView,
                    willEndScrollingWithVelocity velocity: CGPoint,
                    targetContentOffset: UnsafeMutablePointer<CGPoint>)
}
