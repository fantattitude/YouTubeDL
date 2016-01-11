import Foundation

enum YouTubeVideoQuality: UInt {
	case Small144pDash = 160 // Encoded in 15 FPS.
	case Small240p = 36

	case Medium360p = 18
	case Medium480pDash = 135

	case HD720p = 22
	case HD720pDash = 136
	case HD720p60Dash = 298

	case HD1080p = 37 // Not used anymore
	case HD1080pDash = 137
	case HD1080p60Dash = 299

	case HD2160pDash = 138


	var isDash: Bool {
		return [.Small144pDash, .Medium480pDash, .HD720pDash, .HD720p60Dash, .HD1080pDash, .HD1080p60Dash, .HD2160pDash].contains(self)
	}

	var stringValue: String {
		switch (self) {
		case .Small144pDash:
			return "144p (Dash)"
		case .Small240p:
			return "240p"
		case .Medium360p:
			return "360p"
		case .Medium480pDash:
			return "480p (Dash)"
		case .HD720p:
			return "720p"
		case .HD720pDash:
			return "720p (Dash)"
		case .HD720p60Dash:
			return "720p60 (Dash)"
		case .HD1080p:
			return "1080p"
		case .HD1080pDash:
			return "1080p (Dash)"
		case .HD1080p60Dash:
			return "1080p60 (Dash)"
		case .HD2160pDash: 
			return "2160p (Dash)"
		}
	}
}

enum YouTubeAudioQuality: UInt {
	case Medium128kbps = 140
	case High256kbps = 141 // Available in the DASH manifest and on YouTube's content distribution servers, but not used in playback.
}

extension YouTubeVideoQuality: Comparable {
	func compare(other: YouTubeVideoQuality) -> NSComparisonResult {
		return self.stringValue.localizedStandardCompare(other.stringValue)
	}
}

func <(lhs: YouTubeVideoQuality, rhs: YouTubeVideoQuality) -> Bool {
	return lhs.compare(rhs) == .OrderedAscending
}

func <=(lhs: YouTubeVideoQuality, rhs: YouTubeVideoQuality) -> Bool {
	return [.OrderedSame, .OrderedAscending].contains(lhs.compare(rhs))
}

func >=(lhs: YouTubeVideoQuality, rhs: YouTubeVideoQuality) -> Bool {
	return [.OrderedSame, .OrderedDescending].contains(lhs.compare(rhs))
}

func >(lhs: YouTubeVideoQuality, rhs: YouTubeVideoQuality) -> Bool {
	return lhs.compare(rhs) == .OrderedDescending
}
