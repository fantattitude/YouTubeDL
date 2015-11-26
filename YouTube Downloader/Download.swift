import UIKit

struct Download: Encodable {
	enum Status: String {
		case Downloading
		case ReadyToPlay
	}

	var name: String
	var path: String
	var thumbnail: UIImage?
	var status: Status

	init?(dictionaryRepresentation: NSDictionary?) {
		guard let
			dic = dictionaryRepresentation,
			name = dic["name"] as? String,
			path = dic["path"] as? String,
			statusString = dic["status"] as? String,
			status = Status(rawValue: statusString) else { return nil }

		self.name = name
		self.path = path
		self.status = status

		if let thumbnail = dic["thumbnail"] as? NSData {
			self.thumbnail = UIImage(data: thumbnail)
		}
	}

	func encode() -> NSDictionary {
		var representation: [String: AnyObject] = [
			"name": name,
			"path": path,
			"status": status.rawValue
		]
		if let thumbnail = thumbnail, thumbnailData = UIImagePNGRepresentation(thumbnail) {
			representation["thumbnail"] = thumbnailData
		}
		return representation
	}
}