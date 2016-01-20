import Foundation
import XCDYouTubeKit

enum YouTubeHelperError: ErrorType {
	case RegexCreationError
}

class YouTubeHelper {
	let youTubeURLPattern = "(?:youtube\\.com/(?:[^/]+/.+/|(?:v|e(?:mbed)?)/|.*[?&]v=)|youtu\\.be/)([^\"&?/ ]{11}).*"

	func identifierFromYouTubeURL(url: String) -> String? {
		guard let
			regex = try? NSRegularExpression(pattern: youTubeURLPattern, options: [.CaseInsensitive]),
			range = regex.firstMatchInString(url, options: [], range: (url as NSString).rangeOfString(url))?.rangeAtIndex(1)
			else { return nil }

		return (url as NSString).substringWithRange(range)
	}

	func videoWithURL(url: String, completion: (XCDYouTubeVideo?, ErrorType?) -> Void) {
		guard let identifier = identifierFromYouTubeURL(url) else {
			completion(nil, YouTubeHelperError.RegexCreationError)
			return
		}

		XCDYouTubeClient.defaultClient().getVideoWithIdentifier(identifier, completionHandler: completion)
	}
}
