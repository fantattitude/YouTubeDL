import Foundation
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

	var completionBlocks: [(DownloadManager) -> Void] = []

	func aVideoCompleted(completed: (DownloadManager) -> Void) {
		completionBlocks.append(completed)
	}

	func addVideo(videoUrl: NSURL, audioUrl: NSURL? = nil, name: String, identifier: String, progress: (Int64, Int64, Int64) -> Void, completion: (Bool) -> Void) {
		let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]

		var currentDownload = Download(name: name, identifier: identifier, videoPath: path + "/" + identifier + ".mp4")

		if let audioUrl = audioUrl {
			currentDownload.audioPath = path + "/" + identifier + ".m4a"

			Alamofire.download(.GET, audioUrl) { tempURL, response in
				return NSURL(fileURLWithPath: currentDownload.audioPath!)
			}
		}

		currentDownload.request = Alamofire.download(.GET, videoUrl) { tempURL, response in
			return NSURL(fileURLWithPath: currentDownload.videoPath)
			}.response { _, _, _, error in
				guard error == nil else { return }
				currentDownload.status = .ReadyToPlay
				self.completionBlocks.forEach { $0(self) }
				self.completionBlocks.removeAll()
		}

		downloads.append(currentDownload)
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
