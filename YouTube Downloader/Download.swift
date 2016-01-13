import UIKit
import AVFoundation
import Alamofire

final class Download {
	enum Status: String {
		case Downloading
		case ReadyToPlay
	}

	var name: String!
	var identifier: String!
	var quality: YouTubeVideoQuality!
	var videoUrl: String!
	var videoPath: String?
	var audioUrl: String?
	var audioPath: String?
	var thumbnail: UIImage?
	var status: Status!

	var videoRequest: Alamofire.Request?
	var audioRequest: Alamofire.Request?

	lazy var documentsPath = {
		return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
	}()

	init(name: String, identifier: String, quality: YouTubeVideoQuality!, videoUrl: String, videoPath: String? = nil, audioUrl: String? = nil, audioPath: String? = nil, status: Status = .Downloading) {
		self.name = name
		self.identifier = identifier
		self.videoUrl = videoUrl
		self.videoPath = videoPath
		self.audioUrl = audioUrl
		self.audioPath = audioPath
		self.status = status
	}

	private static let dateComponentsFormatter = NSDateComponentsFormatter()
	var videoLength: String? {
		guard let videoPath = videoPath else { return nil }

		let videoAsset = AVURLAsset(URL: NSURL(fileURLWithPath: documentsPath + "/" + videoPath))
		let videoDuration: Int32

		if audioPath != nil {
			videoDuration = Int32((videoAsset.duration.value - (videoAsset.duration.value / 2))) / videoAsset.duration.timescale
		} else {
			videoDuration = Int32(videoAsset.duration.value) / videoAsset.duration.timescale
		}

		guard videoDuration > 0 else { return nil }

		return Download.dateComponentsFormatter.stringFromTimeInterval(Double(videoDuration))
	}

	var player: AVPlayer? {
		guard let videoPath = videoPath else { return nil }

		if let soundPath = audioPath {
			let composition = AVMutableComposition()

			let audioURL = NSURL(fileURLWithPath: documentsPath + "/" + soundPath)
			let audioAsset = AVURLAsset(URL: audioURL)
			let audioTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(audioAsset.duration.value - (audioAsset.duration.value / 2), audioAsset.duration.timescale))

			let bCompositionAudioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
			try! bCompositionAudioTrack.insertTimeRange(audioTimeRange, ofTrack: audioAsset.tracksWithMediaType(AVMediaTypeAudio)[0], atTime: kCMTimeZero)

			let videoURL = NSURL(fileURLWithPath: documentsPath + "/" + videoPath)
			let videoAsset = AVURLAsset(URL: videoURL)
			let videoTimeRange = audioTimeRange

			//Now we are creating the second AVMutableCompositionTrack containing our video and add it to our AVMutableComposition object.
			let aCompositionVideoTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
			try! aCompositionVideoTrack.insertTimeRange(videoTimeRange, ofTrack: videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: kCMTimeZero)

			let playerItem = AVPlayerItem(asset: composition)
			return AVPlayer(playerItem: playerItem)
		}

		return AVPlayer(URL: NSURL(fileURLWithPath: documentsPath + "/" + videoPath))
	}
}

extension Download: CustomStringConvertible {
	var description: String {
		return "\(name) (\(identifier)) - \(status.rawValue)"
	}
}

extension Download: Encodable {
	convenience init?(dictionaryRepresentation: NSDictionary?) {
		guard let
			dic = dictionaryRepresentation,
			name = dic["name"] as? String,
			identifier = dic["identifier"] as? String,
			qualityRaw = dic["quality"] as? UInt,
			quality = YouTubeVideoQuality(rawValue: qualityRaw),
			videoUrl = dic["videoUrl"] as? String,
			statusString = dic["status"] as? String,
			status = Status(rawValue: statusString) else { return nil }

		self.init(
			name: name,
			identifier: identifier,
			quality: quality,
			videoUrl: videoUrl,
			videoPath: dic["videoPath"] as? String,
			audioUrl: dic["audioUrl"] as? String,
			audioPath: dic["audioPath"] as? String, 
			status: status
		)

		if let thumbnail = dic["thumbnail"] as? NSData {
			self.thumbnail = UIImage(data: thumbnail)
		}
	}

	func encode() -> NSDictionary {
		var representation: [String: AnyObject] = [
			"name": name,
			"identifier": identifier,
			"quality": quality.rawValue,
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