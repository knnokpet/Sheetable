import UIKit
import Sheetable

class ViewController: UIViewController {
    
    var overlayStackcontroller: OverlayViewStackController!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.overlayStackcontroller = OverlayViewStackController(parentViewController: self)
    }
    
    @IBAction func moveCurrentSheetBySegmentedControl(_ sender: Any) {
        guard let segmentedControl = sender as? UISegmentedControl else { return }
        
        let mode: OverlayMode = {
            switch segmentedControl.selectedSegmentIndex {
            case 0 :
                return .bottom
            case 1:
                return .middle
            case 2:
                return .fullScreen
            default:
                return .middle
            }
        }()
        
        self.overlayStackcontroller.move(to: mode)
    }
    
    @IBAction func addNewSheet(_ sender: Any) {
        self.overlayStackcontroller.add(childViewController: OverlayViewController())
    }
    
    @IBAction func removeCurrentSheet(_ sender: Any) {
        self.overlayStackcontroller.removeCurrentViewController()
    }
    
}

