import Foundation
import Alamofire

class DownloadManager {
	enum DownloadError: ErrorType {
		case AlreadyExists
	}

	static let sharedManager = DownloadManager()
	private init() {}

	var downloads: [Download] = []

	var readyDownload: [Download] {
		return downloads.filter { $0.status == .ReadyToPlay }
	}

	var downloading: [Download] {
		return downloads.filter { $0.status == .Downloading }
	}

	private var completionBlocks: [(DownloadManager) -> Void] = []
	func aVideoCompleted(completed: (DownloadManager) -> Void) {
		completionBlocks.append(completed)
	}

	private var startingBlocks: [() -> Void] = []
	func aVideoStarted(block: () -> Void) {
		startingBlocks.append(block)
	}

	lazy var documentsPath = {
		return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
	}()


	private func deleteFileAtPathIfNecessary(url: NSURL) {
		guard let path = url.path else { return }
		deleteFileAtPathIfNecessary(path)
	}

	private func deleteFileAtPathIfNecessary(path: String) {
		do {
			if NSFileManager.defaultManager().fileExistsAtPath(path) {
				try NSFileManager.defaultManager().removeItemAtPath(path)
			}
		} catch {
			print(error)
		}
	}

	func addDownload(download: Download, progress: ((Double) -> Void)? = nil, completion: ((Bool, ErrorType?) -> Void)? = nil) throws {
		guard !downloads.contains(download) else {
			throw DownloadError.AlreadyExists
		}
		downloads.append(download)

		startingBlocks.forEach { $0() }

		var bothProgress: (video: Double, audio: Double?) = (0.0, nil)
		let bothProgressCalc: () -> Double = {
			if let audio = bothProgress.audio {
				return (bothProgress.video + audio) / 2.0
			}
			return bothProgress.video
		}

		var finished: (video: Bool, audio: Bool?) = (false, nil)
		let finishedBlock: () -> Bool = {
			if let audioFinished = finished.audio {
				return finished.video && audioFinished
			}
			return finished.video
		}

		download.videoRequest = Alamofire.download(.GET, download.videoUrl) { tempURL, response in
			let path = self.filePathWithIdentifier(download.identifier, type: .Video)
			self.deleteFileAtPathIfNecessary(path)
			return path
		}.progress { _, totalBytesRead, totalBytesExpectedToRead in
			bothProgress.video = Double(totalBytesRead) / Double(totalBytesExpectedToRead)
			let progressVal = bothProgressCalc()
			progress?(progressVal)
			download.progress?(progressVal)
		}.response { _, _, _, error in
			guard error == nil else {
				print(error)
				completion?(false, error)
				return
			}

			do {
				try self.filePathWithIdentifier(download.identifier, type: .Video).setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
			} catch {
				print(error)
			}
			download.videoPath = self.fileNameWithIdentifier(download.identifier, type: .Video)

			finished.video = true
			if finishedBlock() {
				download.status = .ReadyToPlay
				self.saveToDefaults()
				self.completionBlocks.forEach { $0(self) }
				completion?(true, nil)
			}
		}

		guard let audio = download.audioUrl else { return }
		download.audioRequest = Alamofire.download(.GET, audio) { tempURL, response in
			let path = self.filePathWithIdentifier(download.identifier, type: .Audio)
			self.deleteFileAtPathIfNecessary(path)
			return path
			}.progress { _, totalBytesRead, totalBytesExpectedToRead in
				bothProgress.audio = Double(totalBytesRead) / Double(totalBytesExpectedToRead)
				let progressVal = bothProgressCalc()
				progress?(progressVal)
				download.progress?(progressVal)
			}.response { _, _, _, error in
				guard error == nil else {
					print(error)
					completion?(false, error)
					return
				}

				do {
					try self.filePathWithIdentifier(download.identifier, type: .Audio).setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
				} catch {
					print(error)
				}
				download.audioPath = self.fileNameWithIdentifier(download.identifier, type: .Audio)

				finished.audio = true
				if finishedBlock() {
					download.status = .ReadyToPlay
					self.saveToDefaults()
					self.completionBlocks.forEach { $0(self) }
					completion?(true, nil)
				}
		}
	}

	enum FileType: String {
		case Video = ".mp4"
		case Audio = ".m4a"
	}


	func fileNameWithIdentifier(identifier: String, type: FileType) -> String {
		return identifier + type.rawValue
	}

	func filePathWithIdentifier(identifier: String, type: FileType) -> NSURL {
		return NSURL(fileURLWithPath: documentsPath + "/" + fileNameWithIdentifier(identifier, type: type))
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
