/**
Generates a weak pointer to an instance function

- parameter obj:		instance to use
- parameter method:	method to use
- returns: function type
*/
func methodPointer<T: AnyObject>(obj: T, method: (T) -> () -> Void) -> (() -> Void) {
	return { [unowned obj] in
		method(obj)()
	}
}
