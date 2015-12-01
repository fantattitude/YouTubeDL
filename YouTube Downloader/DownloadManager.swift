import Alamofire

class DownloadManager {
	static let sharedManager = DownloadManager()
	private init() {}

	var downloads: [Download] = []

	var readyDownload: [Download] {
		return downloads.filter { $0.status == .ReadyToPlay }
	}

	var downloading: [Download] {
		return downloads.filter { $0.status == .Downloading }
	}

	func addDownload(url: NSURL, name: String) {
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



	func loadFromDefaults() {
		guard let arrayDownloads = NSUserDefaults.standardUserDefaults().objectForKey("downloads") as? [NSDictionary] else { return }
		downloads = arrayDownloads.flatMap(Download.init)
	}

	func saveToDefaults() {
		NSUserDefaults.standardUserDefaults().setObject(readyDownload.map { $0.encode() }, forKey: "downloads")
		NSUserDefaults.standardUserDefaults().synchronize()
	}
}
