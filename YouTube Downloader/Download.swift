import UIKit
import Alamofire

class Download: Encodable {
	enum Status: String {
		case Downloading
		case ReadyToPlay
	}

	var name: String!
	var identifier: String!
	var videoUrl: NSURL!
	var videoPath: String?
	var audioUrl: NSURL?
	var audioPath: String?
	var thumbnail: UIImage?
	var status: Status!

	var videoRequest: Alamofire.Request?
	var audioRequest: Alamofire.Request?

	init(name: String, identifier: String, videoUrl: NSURL, videoPath: String? = nil, audioUrl: NSURL? = nil, audioPath: String? = nil, status: Status = .Downloading) {
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
			videoUrl = dic["videoUrl"] as? NSURL,
			statusString = dic["status"] as? String,
			status = Status(rawValue: statusString) else { return nil }

		self.name = name
		self.identifier = identifier
		self.videoUrl = videoUrl
		self.videoPath = dic["videoPath"] as? String
		self.audioUrl = dic["audioUrl"] as? NSURL
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
			"videoUrl": videoUrl,
			"status": status.rawValue
		]

		if let videoPath = videoPath {
			representation["videoPath"] = videoPath
		}

		if let audioUrl = audioUrl {
			representation["audioUrl"] = audioUrl
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