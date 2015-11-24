import UIKit

extension UIViewController {
	@IBAction func dismissViewController() {
		dismissViewControllerAnimated(true, completion: nil)
	}
}