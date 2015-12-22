import UIKit
import Alamofire

class Download: Encodable {
	enum Status: String {
		case Downloading
		case ReadyToPlay
	}

	var name: String!
	var identifier: String!
	var videoUrl: String!
	var videoPath: String?
	var audioUrl: String?
	var audioPath: String?
	var thumbnail: UIImage?
	var status: Status!

	var request: Alamofire.Request?

	init(name: String, identifier: String, videoUrl: String, videoPath: String? = nil, audioUrl: String? = nil, audioPath: String? = nil, status: Status = .Downloading) {
		self.name = name
		self.identifier = identifier
		self.videoUrl = videoUrl
		self.videoPath = videoPath
		self.audioUrl = audioUrl
		self.audioPath = audioPath
		self.status = status
	}

	required init?(dictionaryRepresentation: NSDictionary?) {
		guard let
			dic = dictionaryRepresentation,
			name = dic["name"] as? String,
			identifier = dic["identifier"] as? String,
			videoUrl = dic["videoUrl"] as? String,
			statusString = dic["status"] as? String,
			status = Status(rawValue: statusString) else { return nil }

		self.name = name
		self.identifier = identifier
		self.videoUrl = videoUrl
		self.videoPath = dic["videoPath"] as? String
		self.audioUrl = dic["audioUrl"] as? String
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
			"status": status.rawValue
		]

		if let videoPath = videoPath {
			representation["videoPath"] = videoPath
		}

		if let audioPath = audioPath {
			representation["audioPath"] = audioPath
		}

		if let thumbnail = thumbnail, thumbnailData = UIImagePNGRepresentation(thumbnail) {
			representation["thumbnail"] = thumbnailData
		}
		return representation
	}
}