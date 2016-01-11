import UIKit
import AVFoundation
import AVKit

class VideoCell: UITableViewCell {
	@IBOutlet private weak var title: UILabel!
	@IBOutlet private weak var rightDetail: UILabel!
	@IBOutlet private weak var progressView: UIProgressView!
	@IBOutlet private weak var thumbImageView: UIImageView!
}

class ListVideosVC: UIViewController {
	var refreshControl: UIRefreshControl!

	private static let dateComponentsFormatter = NSDateComponentsFormatter()

	@IBOutlet private weak var tableView: UITableView! {
		didSet {
			refreshControl = UIRefreshControl()
			refreshControl.addTarget(self, action: "refreshData", forControlEvents: .ValueChanged)
			tableView.addSubview(refreshControl)
		}
	}
	var player: AVPlayer?
	var downloads = [Download]()

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

	func refreshData() {
//		let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
//
//		guard let files = try? NSFileManager.defaultManager().contentsOfDirectoryAtPath(path) else { return }
//		self.files = files.map { path + "/" + $0 }.filter { ($0 as NSString).pathExtension != "m4a" }

		if DownloadManager.sharedManager.downloads.isEmpty {
			DownloadManager.sharedManager.loadFromDefaults()
		}

		downloads = DownloadManager.sharedManager.downloads

		tableView.reloadData()
		refreshControl.endRefreshing()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)

		guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
		tableView.deselectRowAtIndexPath(selectedIndexPath, animated: animated)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		refreshData()
	}

	func deleteAll() {
		let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
		guard let files = try? NSFileManager.defaultManager().contentsOfDirectoryAtPath(path) else { return }
		for file in files {
			try! NSFileManager.defaultManager().removeItemAtPath(path + "/" + file)
		}
	}
}

extension ListVideosVC: UITableViewDataSource {
//	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//		return (DownloadManager.sharedManager.downloading.isEmpty ? 0 : 1) + (DownloadManager.sharedManager.readyDownload.isEmpty ? 0 : 1)
//	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//		if !DownloadManager.sharedManager.downloading.isEmpty && section == 0 {
//			return DownloadManager.sharedManager.downloading.count
//		} else if !DownloadManager.sharedManager.downloading.isEmpty && section == 1 {
//			return DownloadManager.sharedManager.readyDownload.count
//		} else {
//			return DownloadManager.sharedManager.readyDownload.count
//		}
		return downloads.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("VideoCell", forIndexPath: indexPath) as! VideoCell

//		let video: Download
//		switch indexPath.section {
//
//		}
//			= DownloadManager.sharedManager.downloads


		let download = downloads[indexPath.row]

		let videoURL = NSURL(fileURLWithPath: download.videoPath!)
		let videoAsset = AVURLAsset(URL: videoURL)
		let videoDuration: Int32

		if download.audioPath != nil {
			videoDuration = Int32((videoAsset.duration.value - (videoAsset.duration.value / 2))) / videoAsset.duration.timescale
		} else {
			videoDuration = Int32(videoAsset.duration.value) / videoAsset.duration.timescale
		}

		cell.title.text = download.name
		cell.rightDetail.text = ListVideosVC.dateComponentsFormatter.stringFromTimeInterval(Double(videoDuration))

		return cell
	}

	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		guard editingStyle == .Delete else { return }

		downloads.removeAtIndex(indexPath.row)
		tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
	}

//	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//		switch section {
//		case 0:
//			return "Downloading"
//		case 1:
//			return "Downloaded"
//		default:
//			return nil
//		}
//	}
}

extension ListVideosVC: UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let download = downloads[indexPath.row]

		if let soundPath = download.audioPath {
			let composition = AVMutableComposition()

			let audioURL = NSURL(fileURLWithPath: soundPath)
			let audioAsset = AVURLAsset(URL: audioURL)
			let audioTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(audioAsset.duration.value - (audioAsset.duration.value / 2), audioAsset.duration.timescale))

			let bCompositionAudioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
			try! bCompositionAudioTrack.insertTimeRange(audioTimeRange, ofTrack: audioAsset.tracksWithMediaType(AVMediaTypeAudio)[0], atTime: kCMTimeZero)

			let videoURL = NSURL(fileURLWithPath: download.videoPath!)
			let videoAsset = AVURLAsset(URL: videoURL)
			let videoTimeRange = audioTimeRange

			//Now we are creating the second AVMutableCompositionTrack containing our video and add it to our AVMutableComposition object.
			let aCompositionVideoTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
			try! aCompositionVideoTrack.insertTimeRange(videoTimeRange, ofTrack: videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: kCMTimeZero)

			let playerItem = AVPlayerItem(asset: composition)
			player = AVPlayer(playerItem: playerItem)
		} else {
			player = AVPlayer(URL: NSURL(fileURLWithPath: download.videoPath!))
		}

		try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
		let movieVC = AVPlayerViewController()
		movieVC.player = player
		self.presentViewController(movieVC, animated: true) { _ in
			movieVC.player?.play()
		}
	}
}
