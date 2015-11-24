import UIKit
import XCDYouTubeKit
import Alamofire

class DownloadVideoVC: UIViewController, UITextFieldDelegate {
	@IBOutlet private weak var textField: UITextField!
	@IBOutlet private weak var label: UILabel!
	@IBOutlet private weak var image: UIImageView!

	var currentVideo: XCDYouTubeVideo?
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		XCDYouTubeClient.defaultClient().getVideoWithIdentifier(textField.text) { video, error in
			self.currentVideo = video
			self.label.text = video?.title
			guard let thumbnailURL = video?.largeThumbnailURL ?? video?.mediumThumbnailURL ?? video?.smallThumbnailURL else { return }

			Alamofire.request(.GET, thumbnailURL).responseData { response in
				guard let data = response.data else { return }

				dispatch_async(dispatch_get_main_queue()) {
					self.image.image = UIImage(data: data)
				}
			}
		}

		return false
	}

	@IBAction func downloadCurrentVideo() {
		guard let currentVideo = currentVideo else { return }

		let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]

		if let video = currentVideo.streamURLs[XCDYouTubeVideoQualityDash.Dash1080p60Video.rawValue] as? NSURL, audio = currentVideo.streamURLs[XCDYouTubeVideoQualityDash.Dash128Audio.rawValue] as? NSURL {
			print("Downloading as DASH")
			print("video : \(video)")
			print("audio : \(audio)")

			Alamofire.download(.GET, video) { tempURL, response -> NSURL in
				return NSURL(fileURLWithPath: path + "/" + currentVideo.identifier + ".mp4")
			}.progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
					print("\(bytesRead) — \(totalBytesRead) — \(totalBytesExpectedToRead)")
			}

			Alamofire.download(.GET, audio) { tempURL, response -> NSURL in
				return NSURL(fileURLWithPath: path + "/" + currentVideo.identifier + ".m4a")
			}.progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
				print("\(bytesRead) — \(totalBytesRead) — \(totalBytesExpectedToRead)")
			}
		} else {
			guard let streamURL = (currentVideo.streamURLs[XCDYouTubeVideoQuality.HD720.rawValue] ?? currentVideo.streamURLs[XCDYouTubeVideoQuality.Medium360.rawValue] ?? currentVideo.streamURLs[XCDYouTubeVideoQuality.Small240.rawValue]) as? NSURL else { return }

			Alamofire.download(.GET, streamURL) { tempURL, response -> NSURL in
				return NSURL(fileURLWithPath: path + "/" + currentVideo.identifier + ".mp4")
			}.progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
				print("\(bytesRead) — \(totalBytesRead) — \(totalBytesExpectedToRead)")
			}
		}
	}
}
