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

	lazy var documentsPath = {
		return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
	}()

	func addDownload(download: Download, progress: (Double) -> Void, completion: (Bool, ErrorType?) -> Void) {
		downloads.append(download)

		var bothProgress: (video: Double, audio: Double?) = (0.0, nil)
		let bothProgressCalc: () -> Double = {
			if let audio = bothProgress.audio {
				return (bothProgress.video + audio) / 2.0
			}
			return bothProgress.video
		}

		download.videoRequest = Alamofire.download(.GET, download.videoUrl) { tempURL, response in
			return self.filePathWithIdentifier(download.identifier, type: .Video)
		}.progress { _, totalBytesRead, totalBytesExpectedToRead in
			bothProgress.video = Double(totalBytesRead) / Double(totalBytesExpectedToRead)
			progress(bothProgressCalc())
		}.response { _, _, _, error in
			guard error == nil else {
				print(error)
				return completion(false, error)
			}
			download.videoPath = self.filePathWithIdentifier(download.identifier, type: .Audio).absoluteString
			completion(true, nil)
		}

		guard let audio = download.audioUrl else { return }
		download.audioRequest = Alamofire.download(.GET, audio) { tempURL, response in
			return self.filePathWithIdentifier(download.identifier, type: .Audio)
			}.progress { _, totalBytesRead, totalBytesExpectedToRead in
				bothProgress.audio = Double(totalBytesRead) / Double(totalBytesExpectedToRead)
				progress(bothProgressCalc())
			}.response { _, _, _, error in
				guard error == nil else {
					print(error)
					return completion(false, error)
				}
				download.audioPath = self.filePathWithIdentifier(download.identifier, type: .Audio).absoluteString
				download.status = .ReadyToPlay
				completion(true, nil)
		}
	}

	enum FileType: String {
		case Video = ".mp4"
		case Audio = ".m4a"
	}

	func filePathWithIdentifier(identifier: String, type: FileType) -> NSURL {
		return NSURL(fileURLWithPath: self.documentsPath + "/" + identifier + type.rawValue)
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
