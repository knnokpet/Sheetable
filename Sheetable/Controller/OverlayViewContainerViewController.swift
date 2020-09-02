import UIKit

protocol OverlayViewContainerViewControllerDelegate: class {
    func overlayViewContainerViewControllerWillTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator)
    func overlayViewContainerViewControllertraitCollectionDidChange(_ previousTraitCollection: UITraitCollection?, currentTraitCollection: UITraitCollection)
}

class OverlayViewContainerViewController: UIViewController {
    
    weak var delegate: OverlayViewContainerViewControllerDelegate?
    
    var shadowView: CoverShadowView!
    
    // MARK: - View Cycle
    override func loadView() {
        self.view = PassThroughView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureShadowView()
    }
    
    private func configureShadowView() {
        let shadowView = CoverShadowView()
        self.view.addSubview(shadowView)
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0) .isActive = true
        shadowView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
        shadowView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0).isActive = true
        shadowView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0).isActive = true
        self.shadowView = shadowView
    }
    
    // MARK: - Layout
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        delegate?.overlayViewContainerViewControllerWillTransition(to: newCollection, with: coordinator)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        delegate?.overlayViewContainerViewControllertraitCollectionDidChange(previousTraitCollection, currentTraitCollection: self.traitCollection)
    }
    
}
