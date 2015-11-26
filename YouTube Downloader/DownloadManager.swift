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

	func loadFromDefaults() {
		guard let arrayDownloads = NSUserDefaults.standardUserDefaults().objectForKey("downloads") as? [NSDictionary] else { return }
		downloads = arrayDownloads.flatMap(Download.init)
	}

	func saveToDefaults() {
		NSUserDefaults.standardUserDefaults().setObject(readyDownload.map { $0.encode() }, forKey: "downloads")
		NSUserDefaults.standardUserDefaults().synchronize()
	}
}
