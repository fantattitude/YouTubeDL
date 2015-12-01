import UIKit
import XCDYouTubeKit
import Alamofire

class DownloadVideoVC: UIViewController, UITextFieldDelegate {
	@IBOutlet private weak var textField: UITextField!
	@IBOutlet private weak var label: UILabel!
	@IBOutlet private weak var image: UIImageView!
	@IBOutlet private weak var progressView: UIProgressView!
	@IBOutlet private weak var statusLabel: UILabel!

	var currentVideo: XCDYouTubeVideo?
	var currentDownload: (video: Alamofire.Request?, audio: Alamofire.Request?)
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		loadVideoInfos()
		return false
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

	@IBAction func loadVideoInfos() {
		guard let
			text = textField.text,
			regex = try? NSRegularExpression(pattern: "(?:youtube\\.com/(?:[^/]+/.+/|(?:v|e(?:mbed)?)/|.*[?&]v=)|youtu\\.be/)([^\"&?/ ]{11}).*", options: [.CaseInsensitive])
			else { return }

		if let range = regex.firstMatchInString(text, options: [], range: (text as NSString).rangeOfString(text))?.rangeAtIndex(1) {
			XCDYouTubeClient.defaultClient().getVideoWithIdentifier((text as NSString).substringWithRange(range)) { video, error in
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
		}
	}

	@IBAction func downloadCurrentVideo() {
		guard let
			currentVideo = currentVideo,
			streamURLs = currentVideo.streamURLs as? [UInt: NSURL]
			else { return }

		let alertController = UIAlertController(title: "Quelle qualité souhaitez vous charger ?", message: "Qualités disponibles :", preferredStyle: .ActionSheet)
		streamURLs.keys
			.flatMap { YouTubeVideoQuality(rawValue: $0) }
			.sort { $0.stringValue > $1.stringValue }
			.forEach { quality in
			alertController.addAction(UIAlertAction(title: quality.stringValue, style: .Default, handler: { _ in
				self.loadVideo(currentVideo, withQuality: quality)
			}))
		}
		alertController.addAction(UIAlertAction(title: "Annuler", style: .Cancel, handler: nil))
		presentViewController(alertController, animated: true, completion: nil)

	}


	func stopDownload() {
		currentDownload.video?.cancel()
		currentDownload.audio?.cancel()
		currentDownload = (nil, nil)
		currentProgress = (nil, nil)

		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismissViewController")
	}

	private func loadVideo(video: XCDYouTubeVideo, withQuality quality: YouTubeVideoQuality) {
		guard let videoURL = video.streamURLs[quality.rawValue] else { return }

		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "stopDownload")
		progressView.setProgress(0, animated: true)

		let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]

		if quality.isDash {
			guard let audioURL = video.streamURLs[YouTubeAudioQuality.Medium128kbps.rawValue] else { return }

			currentDownload.audio = Alamofire.download(.GET, audioURL) { tempURL, response in
				return NSURL(fileURLWithPath: path + "/" + video.identifier + ".m4a")
				}.progress { _, totalBytesRead, totalBytesExpectedToRead in
					self.updateStatus(.Audio, bytesRead: 0, totalBytesRead: totalBytesRead, totalBytesExpectedToRead: totalBytesExpectedToRead)
				}.response { _, _, _, error in
					if let error = error {
						self.statusLabel.text = "Failed with error: \(error)"
					} else {
						self.statusLabel.text = "Downloaded file successfully"
					}
			}
		}

		currentDownload.video = Alamofire.download(.GET, videoURL) { tempURL, response in
			return NSURL(fileURLWithPath: path + "/" + video.identifier + ".mp4")
			}.progress { _, totalBytesRead, totalBytesExpectedToRead in
				self.updateStatus(.Video, bytesRead: 0, totalBytesRead: totalBytesRead, totalBytesExpectedToRead: totalBytesExpectedToRead)
			}.response { _, _, _, error in
				if let error = error {
					self.statusLabel.text = "Failed with error: \(error)"
				} else {
					self.statusLabel.text = "Downloaded file successfully"
				}
		}
	}

	private enum Type {
		case Video
		case Audio
	}

	private var currentProgress: (video: Float?, audio: Float?)

	private func updateStatus(type: Type, bytesRead: Int64, totalBytesRead: Int64, totalBytesExpectedToRead: Int64) {
		let progress: Float

		switch type {
		case .Video:
			currentProgress.video = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
		case .Audio:
			currentProgress.audio = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
		}

		if let audioProgress = currentProgress.audio, videoProgress = currentProgress.video {
			progress = (videoProgress + audioProgress) / 2.0
		} else if let videoProgress = currentProgress.video {
			progress = videoProgress
		} else {
			progress = 0.0
		}


		dispatch_async(dispatch_get_main_queue()) {
			self.progressView.setProgress(progress, animated: true)
		}
	}
}
