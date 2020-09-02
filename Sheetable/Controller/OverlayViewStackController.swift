import UIKit

public enum OverlayMode {
    case fullScreen, middle, bottom, progressing
}

public class OverlayViewStackController: NSObject {
    
    // MARK: - Properties
    weak var parentViewController: UIViewController?
    var transitionCoordinator: OverlayViewTransitionCoordinator?
    private(set) lazy var containerViewController = OverlayViewContainerViewController()
    
    private var viewControllers: [UIViewController] = []
    private var parameters: [OverlayViewLayoutConstraintParameter] = []
    
    var currentOverlayViewHeightConstant: CGFloat = 0
    internal var currentOverlayMode: OverlayMode = .middle
    var overlayModeBeforeProgressing: OverlayMode = .middle
    private var offsetBeganDragging: CGPoint = .zero
    
    // MARK: Calculated Properties
    internal var currentOverlayViewController: UIViewController? {
        guard viewControllers.count > 0 else {
            return nil
        }
        return viewControllers[0]
    }
    
    internal var currentParameter: OverlayViewLayoutConstraintParameter? {
        guard parameters.count > 0 else {
            return nil
        }
        return parameters[0]
    }
    
    internal var previousOverlayViewController: UIViewController? {
        guard viewControllers.count > 1 else {
            return nil
        }
        return viewControllers[1]
    }
    
    internal var previousParameter: OverlayViewLayoutConstraintParameter? {
        guard parameters.count > 1 else {
            return nil
        }
        return parameters[1]
    }
    
    var numberOfViewControllers: Int {
        return self.viewControllers.count
    }
    
    // MARK: - Initialize
    public init(parentViewController: UIViewController) {
        super.init()
        self.parentViewController = parentViewController
        self.transitionCoordinator = OverlayViewTransitionCoordinator(stackController: self)
        self.transitionCoordinator?.delegate = self
        
        configureContainerViewController()
        configureNotification()
    }
    
    private func configureContainerViewController() {
        
        guard let parentViewController = self.parentViewController else { return }
        
        parentViewController.addChild(self.containerViewController)
        parentViewController.view.addSubview(self.containerViewController.view)
        self.containerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.containerViewController.view.topAnchor.constraint(equalTo: parentViewController.view.topAnchor).isActive = true
        self.containerViewController.view.leftAnchor.constraint(equalTo: parentViewController.view.leftAnchor).isActive = true
        self.containerViewController.view.rightAnchor.constraint(equalTo: parentViewController.view.rightAnchor).isActive = true
        self.containerViewController.view.bottomAnchor.constraint(equalTo: parentViewController.view.bottomAnchor).isActive = true
        self.containerViewController.didMove(toParent: self.parentViewController)
        self.containerViewController.delegate = self
    }
    
    private func configureNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(removeCurrentViewController), name: .dismissOverlayView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(move(_:)), name: .moveOverlayView, object: nil)
    }
    
    // MARK: - Setter
    func setCurrentParameter(_ parameter: OverlayViewLayoutConstraintParameter) {
        parameters[0] = parameter
    }
    
    // MARK: - Manage Overlay View Controller
    public func add(childViewController viewController: Sheetable) {
        
        guard let _ = self.parentViewController else { return }
        
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        containerViewController.addChild(viewController)
        containerViewController.view.addSubview(viewController.view)
        
        let topSpaceConstraint = viewController.view.topAnchor.constraint(equalTo: containerViewController.view.topAnchor, constant: containerViewController.view.bounds.height)
        topSpaceConstraint.priority = .required
        topSpaceConstraint.isActive = true
        topSpaceConstraint.identifier = "portrait top"
        
        let strechingHeightConstraint =  viewController.view.heightAnchor.constraint(equalToConstant: 0.0)
        strechingHeightConstraint.priority = .defaultLow
        strechingHeightConstraint.isActive = true
        
        let left = viewController.view.leftAnchor.constraint(equalTo: containerViewController.view.leftAnchor, constant: 0.0)
        left.isActive = true
        left.identifier = "portrait left"
        
        let right = viewController.view.rightAnchor.constraint(equalTo: containerViewController.view.rightAnchor, constant: 0.0)
        right.isActive = true
        right.identifier = "portrait right"
        
        let bottom = viewController.view.bottomAnchor.constraint(equalTo: containerViewController.view.bottomAnchor, constant: 0.0)
        bottom.priority = .defaultHigh
        bottom.isActive = true
        bottom.identifier = "portrait bottom"
        
        //
        let landscapeTop = viewController.view.topAnchor.constraint(equalTo: containerViewController.view.topAnchor, constant: containerViewController.view.safeAreaInsets.top)
        landscapeTop.priority = .defaultHigh
        landscapeTop.isActive = false
        landscapeTop.identifier = "landscape top"
        
        let landscapeLeftConstant: CGFloat = {
            if containerViewController.view.traitCollection.verticalSizeClass == .compact {
                return containerViewController.view.safeAreaInsets.left
            } else {
                return containerViewController.view.safeAreaInsets.top
            }
        }()
        let landscapeLeft = viewController.view.leftAnchor.constraint(equalTo: containerViewController.view.leftAnchor, constant: landscapeLeftConstant)
        landscapeLeft.isActive = false
        landscapeLeft.identifier = "landscape left"
        
        let screenPercentage: CGFloat = {
            if containerViewController.view.traitCollection.verticalSizeClass == .compact {
                return containerViewController.view.bounds.height / containerViewController.view.bounds.width
            } else {
                return containerViewController.view.bounds.width / containerViewController.view.bounds.height
            }
        }()
        
        let usableHeight: CGFloat = {
            if containerViewController.view.traitCollection.verticalSizeClass == .compact {
                return containerViewController.view.bounds.height
            } else {
                return containerViewController.view.bounds.width
            }
        }()
        
        let widthConstraint = viewController.view.widthAnchor.constraint(equalToConstant: usableHeight * screenPercentage * 1.8)
        widthConstraint.isActive = false
        widthConstraint.identifier = "landscape width"
        
        let landscapeBottom = viewController.view.bottomAnchor.constraint(equalTo: containerViewController.view.bottomAnchor, constant: 0.0)
        landscapeBottom.isActive = false
        landscapeBottom.identifier = "landscape bottom"
        
        
        let parameter = OverlayViewLayoutConstraintParameter(portraitTopConstraint: topSpaceConstraint, portraitLeftConstraint: left, portraitRightConstraint: right, portraitBottomConstraint: bottom, landscapeTopConstraint: landscapeTop, landscapeLeftConstraint: landscapeLeft, landscapeWidthConstraint: widthConstraint, landscapeBottomConstraint: landscapeBottom)

        self.add(viewController: viewController, parameter: parameter)
                self.transitionCoordinator?.setupViewConfiguration(containerViewController.traitCollection)
        
        viewController.didMove(toParent: containerViewController)
        
        if viewController is SheetScrollTransitionDelegatable {
            (viewController as! SheetScrollTransitionDelegatable).delegator.delegate = self
        }
        
        self.transitionCoordinator?.present(completionHandler: { (finished) in
            if finished {
                
            }
        })

    }
    
    private func add(viewController: Sheetable, parameter: OverlayViewLayoutConstraintParameter) {
        self.viewControllers.insert(viewController, at: 0)
        self.parameters.insert(parameter, at: 0)
    }
    
    private var removeProcessedViewControllers: Set<UIViewController> = []
    private var removeProcessedParameters: Set<OverlayViewLayoutConstraintParameter> = []
    
    @objc public func removeCurrentViewController() {
        
        guard
            self.viewControllers.count > 0,
            self.parameters.count > 0
        else
        { return }
        
        let viewController = self.viewControllers[0]
        viewController.willMove(toParent: nil)
        let parameter = self.parameters[0]
        
        let previous: UIViewController? = {
            let index = 1
            guard self.viewControllers.count > index else { return nil }
            
            return viewControllers[1]
            
        }()
        
        removeProcessedViewControllers.insert(viewController)
        removeProcessedParameters.insert(parameter)
        
        self.viewControllers.remove(at: 0)
        self.parameters.remove(at: 0)
        
        self.transitionCoordinator?.remove(viewController, parameter: parameter, previousViewController: previous, completionHandler: { (isFinished) in
            if isFinished {
                if let index = self.removeProcessedParameters.firstIndex(of: parameter) {
                    self.removeProcessedParameters.remove(at: index)
                }
                if
                    self.removeProcessedViewControllers.contains(viewController),
                    let index = self.removeProcessedViewControllers.firstIndex(of: viewController)
                {
                    self.removeProcessedViewControllers.remove(at: index)
                }
            }
        })
        
    }
    
    public func move(to mode: OverlayMode) {
        self.transitionCoordinator?.move(mode: mode, recognizer: nil, velocity: nil, duration: nil)
    }
    
    @objc internal func move(_ notification: Notification) {
        guard let toMode = notification.userInfo?[OverlayViewNotificationProperty.mode] as? OverlayMode else { return }
        self.transitionCoordinator?.move(mode: toMode, recognizer: nil, velocity: nil, duration: nil)
    }
    
}

extension OverlayViewStackController: SheetScrollDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.overlayModeBeforeProgressing = self.currentOverlayMode
        self.transitionCoordinator?.beginOverlayViewTranslation()
        self.offsetBeganDragging = scrollView.contentOffset
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard shouldTranslateView(following: scrollView) else { return }
        self.currentOverlayMode = .progressing
        translateView(following: scrollView)
    }
    
    func scrollView(_ scrollView: UIScrollView, willEndScrollingWithVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        switch self.currentOverlayMode {
        case .fullScreen:
            break
        case .bottom, .middle, .progressing:
            targetContentOffset.pointee = .zero
        }
        let translation = scrollView.panGestureRecognizer.translation(in: self.currentOverlayViewController?.view)
        let adjustedTranslation = CGPoint(x: translation.x, y: translation.y - offsetBeganDragging.y)
        self.transitionCoordinator?.endOverlayViewTranslation(adjustedTranslation, recognizer: scrollView.panGestureRecognizer)
    }
    
    func shouldTranslateView(following scrollView: UIScrollView) -> Bool {
        guard scrollView.isTracking else { return false }
        
        let offset = scrollView.contentOffset.y
        switch self.currentOverlayMode {
        case .progressing:
            return true
        case .fullScreen:
            return offset < 0
        case .bottom:
            return true
            //return offset > 0
        case .middle:
            return true
        }
    }
    
    func translateView(following scrollView: UIScrollView) {
        scrollView.contentOffset = .zero
        let translation = scrollView.panGestureRecognizer.translation(in: self.containerViewController.view)
        let adjustedTranslation = CGPoint(x: translation.x, y: translation.y - offsetBeganDragging.y)
        self.transitionCoordinator?.translateOverlayView(adjustedTranslation)
    }
    
}

extension OverlayViewStackController: OverlayViewContainerViewControllerDelegate {
    func overlayViewContainerViewControllerWillTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        
    }
    
    func overlayViewContainerViewControllertraitCollectionDidChange(_ previousTraitCollection: UITraitCollection?, currentTraitCollection: UITraitCollection) {
        self.transitionCoordinator?.handleTraitcollectionDidChange(previousTraitCollection, currentTraitCollection: currentTraitCollection)
    }
    
    
}

extension OverlayViewStackController: FloatViewTransitionCoordinatorDelegate {
    func didReachToMaximumPosition(_ coordinator: OverlayViewTransitionCoordinator) {
        self.currentOverlayMode = .fullScreen
    }
    
    func didChangeBackgroundShadowViewVisibility(_ isHidden: Bool, percentage: Float?) {
        if let percentage = percentage {
            self.containerViewController.shadowView.setShadowVisibility(CGFloat(percentage))
        } else {
            self.containerViewController.shadowView.isHiddenShadowView = isHidden
        }
    }
}
