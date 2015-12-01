import UIKit

struct Download: Encodable {
	enum Status: String {
		case Downloading
		case ReadyToPlay
	}

	var name: String
	var identifier: String
	var videoPath: String
	var audioPath: String?
	var thumbnail: UIImage?
	var status: Status

	var progressBlocks: [(bytesRead: Int64, totalBytesRead: Int64, totalBytesExpectedToRead: Int64) -> Void] = []

	init?(dictionaryRepresentation: NSDictionary?) {
		guard let
			dic = dictionaryRepresentation,
			name = dic["name"] as? String,
			identifier = dic["identifier"] as? String,
			videoPath = dic["videoPath"] as? String,
			statusString = dic["status"] as? String,
			status = Status(rawValue: statusString) else { return nil }

		self.name = name
		self.identifier = identifier
		self.videoPath = videoPath
		self.audioPath = dic["audioPath"] as? String
		self.status = status

		if let thumbnail = dic["thumbnail"] as? NSData {
			self.thumbnail = UIImage(data: thumbnail)
		}
	}

	func encode() -> NSDictionary {
		var representation: [String: AnyObject] = [
			"name": name,
			"identifier": identifier,
			"videoPath": videoPath,
			"status": status.rawValue
		]

		if let audioPath = audioPath {
			representation["audioPath"] = audioPath
		}

		if let thumbnail = thumbnail, thumbnailData = UIImagePNGRepresentation(thumbnail) {
			representation["thumbnail"] = thumbnailData
		}
		return representation
	}
}