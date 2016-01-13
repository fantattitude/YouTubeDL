import UIKit
import XCDYouTubeKit
import Alamofire

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

class DownloadVideoVC: UIViewController, UITextFieldDelegate {
	@IBOutlet private weak var textField: UITextField!
	@IBOutlet private weak var label: UILabel!
	@IBOutlet private weak var image: UIImageView!
	@IBOutlet private weak var progressView: UIProgressView!
	@IBOutlet private weak var statusLabel: UILabel!
	@IBOutlet private weak var pasteButton: UIButton!

	var currentVideo: XCDYouTubeVideo?
	var currentDownload: (video: Alamofire.Request?, audio: Alamofire.Request?)
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		loadVideoInfos()
		return false
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		if let pasteboardString = UIPasteboard.generalPasteboard().string where !pasteboardString.isEmpty && YouTubeHelper().identifierFromYouTubeURL(pasteboardString) != nil {
			UIView.animateWithDuration(0.5, delay: 0.0, options: [.Repeat, .Autoreverse, .AllowUserInteraction], animations: {
				self.pasteButton.alpha = 0.25
				}, completion: nil)
		}
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

	@IBAction func loadVideoInfos() {
		guard let text = textField.text where !text.isEmpty else { return }

		YouTubeHelper().videoWithURL(text) { video, error in
			self.currentVideo = video
			self.label.text = video?.title

			guard let thumbnailURL = video?.largeThumbnailURL ?? video?.mediumThumbnailURL ?? video?.smallThumbnailURL else { return }
			Alamofire.request(.GET, thumbnailURL).responseData { response in
				guard let data = response.data else { return }
				dispatch_main {
					self.image.image = UIImage(data: data)
				}
			}
		}
	}

	@IBAction func paste() {
		UIView.animateWithDuration(0.5, delay: 0.0, options: [.BeginFromCurrentState], animations: {
			self.pasteButton.alpha = 1.0
			}, completion: nil)
		textField.text = UIPasteboard.generalPasteboard().string
		loadVideoInfos()
	}

	@IBAction func downloadCurrentVideo() {
		guard let
			currentVideo = currentVideo,
			streamURLs = currentVideo.streamURLs as? [UInt: NSURL]
			else { return }

		var fileSizes = [UInt: Int64]()
		let supportedFileStreams = streamURLs.filter { YouTubeVideoQuality(rawValue: $0.0) != nil || YouTubeAudioQuality(rawValue: $0.0) != nil }

		supportedFileStreams.forEach { key, value in
			let download = Alamofire.download(.GET, value, destination: Request.suggestedDownloadDestination(directory: .CachesDirectory, domain: .UserDomainMask))

			download.progress { _, _, expectedBytes in
				fileSizes[key] = expectedBytes
				download.cancel()
				dispatch_main {
					guard supportedFileStreams.count == fileSizes.count else { return }

					let alertController = UIAlertController(title: "Quelle qualité souhaitez vous charger ?", message: "Qualités disponibles :", preferredStyle: .ActionSheet)
					streamURLs.keys
						.flatMap { YouTubeVideoQuality(rawValue: $0) }
						.sort(>)
						.forEach { quality in
							let filesize: Double
							if quality.isDash {
								filesize = Double(fileSizes[quality.rawValue]!) + Double(fileSizes[YouTubeAudioQuality.Medium128kbps.rawValue]!)
							} else {
								filesize = Double(fileSizes[quality.rawValue]!)
							}
							alertController.addAction(UIAlertAction(title: quality.stringValue + " — " + String(format: "%1.1f", filesize / pow(10.0, 6) ) + "Mb", style: .Default, handler: { _ in
								self.loadVideo(currentVideo, withQuality: quality)
							}))
					}
					alertController.addAction(UIAlertAction(title: "Annuler", style: .Cancel, handler: nil))
					self.presentViewController(alertController, animated: true, completion: nil)
				}
			}
		}
	}


	func stopDownload() {
		currentDownload.video?.cancel()
		currentDownload.audio?.cancel()
		currentDownload = (nil, nil)

		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismissViewController")
	}

	private func loadVideo(video: XCDYouTubeVideo, withQuality quality: YouTubeVideoQuality) {
		guard let videoURL = video.streamURLs[quality.rawValue] else { return }

		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "stopDownload")
		progressView.setProgress(0, animated: true)

		let download = Download(name: video.title, identifier: video.identifier, quality: quality, videoUrl: videoURL.absoluteString)
		download.thumbnail = image.image

		if quality.isDash {
			download.audioUrl = video.streamURLs[YouTubeAudioQuality.Medium128kbps.rawValue]?.absoluteString
		}

		DownloadManager.sharedManager.addDownload(download, progress: { progress in
			dispatch_main {
				self.progressView.progress = Float(progress)
			}
			}) { success, error in
				guard error == nil && success else {
					print(error)
					return
				}
				self.progressView.progress = 1.0
				self.dismissViewController()
		}
	}

	private func updateStatus(bytesRead: Int64, totalBytesRead: Int64, totalBytesExpectedToRead: Int64) {
		let progress = Float(totalBytesRead) / Float(totalBytesExpectedToRead)

		dispatch_async(dispatch_get_main_queue()) {
			self.progressView.setProgress(progress, animated: true)
		}
	}
}
