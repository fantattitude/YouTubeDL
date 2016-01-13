import UIKit

typealias NotificationToken = NSObjectProtocol

class NotificationManager {
	private let notificationCenter = NSNotificationCenter.defaultCenter()
	private var tokens = [NotificationToken]()

	deinit {
		tokens.forEach(unregisterObserver)
	}

	func unregisterObserver(token: NotificationToken) {
		notificationCenter.removeObserver(token)
	}

	func registerObserver(name: String!, block: NSNotification! -> Void) {
		let token = notificationCenter.addObserverForName(name, object: nil, queue: nil, usingBlock: block)
		tokens.append(token)
	}

	func registerObserver(name: String!, forObject object: AnyObject!, block: NSNotification! -> Void) {
		let token = notificationCenter.addObserverForName(name, object: object, queue: nil, usingBlock: block)

		tokens.append(token)
	}

	func postNotification(name: String!, object: AnyObject!) {
		notificationCenter.postNotificationName(name, object: object)
	}
}

// MARK: - App events
enum NotificationType: String {
	case None
}

extension NotificationManager {
	func registerObserver(type: NotificationType, block: NSNotification! -> Void) {
		registerObserver(type.rawValue, block: block)
	}

	func postNotification(type: NotificationType, object: AnyObject? = nil) {
		postNotification(type.rawValue, object: object)
	}
}

// MARK: - Keyboard
extension NotificationManager {
	/**
	Register a block for execution when UIKeyboardWillShowNotification is posted

	- parameter block: A (NSNotification) -> Void block
	- warning: This is using Apple's blocks API of NSNotificationCenter,
	be aware that you must be very careful with memory management (brace yourselves retain cycles are coming)
	*/
	func keyboardWillShow(block: NSNotification! -> Void) {
		registerObserver(UIKeyboardWillShowNotification, block: block)
	}

	/**
	Register a block for execution when UIKeyboardDidShowNotification is posted

	- parameter block: A (NSNotification) -> Void block
	- warning: This is using Apple's blocks API of NSNotificationCenter,
	be aware that you must be very careful with memory management (brace yourselves retain cycles are coming)
	*/
	func keyboardDidShow(block: NSNotification! -> Void) {
		registerObserver(UIKeyboardDidShowNotification, block: block)
	}

	/**
	Register a block for execution when UIKeyboardWillHideNotification is posted

	- parameter block: A (NSNotification) -> Void block
	- warning: This is using Apple's blocks API of NSNotificationCenter,
	be aware that you must be very careful with memory management (brace yourselves retain cycles are coming)
	*/
	func keyboardWillHide(block: NSNotification! -> Void) {
		registerObserver(UIKeyboardWillHideNotification, block: block)
	}

	/**
	Register a block for execution when UIKeyboardDidHideNotification is posted

	- parameter block: A (NSNotification) -> Void block
	- warning: This is using Apple's blocks API of NSNotificationCenter,
	be aware that you must be very careful with memory management (brace yourselves retain cycles are coming)
	*/
	func keyboardDidHide(block: NSNotification! -> Void) {
		registerObserver(UIKeyboardDidHideNotification, block: block)
	}
}
