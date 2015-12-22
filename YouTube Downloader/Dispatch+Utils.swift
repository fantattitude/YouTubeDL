import Dispatch

func dispatch_main(block: () -> Void) {
	dispatch_async(dispatch_get_main_queue(), block)
}

func dispatch_after(seconds: UInt64, block: () -> Void) {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), block)
}