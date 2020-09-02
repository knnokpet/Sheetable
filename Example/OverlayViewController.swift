import UIKit
import Sheetable

class MyMyCell: UITableViewCell {
    
}

protocol OverlayViewControllerDelegate: class {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollView(_ scrollView: UIScrollView,
                    willEndScrollingWithVelocity velocity: CGPoint,
                    targetContentOffset: UnsafeMutablePointer<CGPoint>)
}

class OverlayViewController: UIViewController, Sheetable, SheetScrollTransitionDelegatable, UITableViewDelegate, UITableViewDataSource {
    let visualEffectView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    
    let shadowView: CoverShadowView = CoverShadowView()
    
    let delegator: SheetScrollDelegator = SheetScrollDelegator()
    
    weak var delegate: OverlayViewControllerDelegate?
    
    private(set) lazy var tableView: UITableView = UITableView()
    private(set) lazy var navigationView: TextFieldNavigationView = TextFieldNavigationView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.view.addSubview(navigationView)
        self.navigationView.translatesAutoresizingMaskIntoConstraints = false
        self.navigationView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        self.navigationView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.navigationView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.navigationView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true

        self.tableView.register(MyMyCell.self, forCellReuseIdentifier: "reuseIdentifier")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = .clear//UIColor.red.withAlphaComponent(0.5)
        self.view.addSubview(self.tableView)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.topAnchor.constraint(equalTo: self.navigationView.bottomAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        
        setupViews()
        
        panGesture()?.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        if cell is MyMyCell {
            cell.textLabel?.text = "\(indexPath.row)"
            cell.backgroundColor = UIColor.clear
        }
        // Configure the cell...

        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegator.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegator.scrollViewDidScroll(scrollView)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegator.scrollView(scrollView, willEndScrollingWithVelocity: velocity, targetContentOffset: targetContentOffset)
    }
}

extension OverlayViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton {
            return false
        }
        return true
    }
}
