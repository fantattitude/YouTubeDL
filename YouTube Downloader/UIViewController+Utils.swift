import UIKit

extension UIViewController {
	@IBAction func dismissViewController() {
		dismissViewControllerAnimated(true, completion: nil)
	}
}

extension UINavigationController {
	public override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return topViewController?.preferredStatusBarStyle() ?? .LightContent
	}
}