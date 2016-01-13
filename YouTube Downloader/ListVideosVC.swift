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

//	func deleteAll() {
//		let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
//		guard let files = try? NSFileManager.defaultManager().contentsOfDirectoryAtPath(path) else { return }
//		for file in files {
//			try! NSFileManager.defaultManager().removeItemAtPath(path + "/" + file)
//		}
//	}
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

		let download = downloads[indexPath.row]

		cell.title.text = download.name
		cell.rightDetail.text = download.videoLength
		cell.thumbImageView.image = download.thumbnail

		return cell
	}

	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		guard editingStyle == .Delete else { return }

		downloads.removeAtIndex(indexPath.row)
		DownloadManager.sharedManager.downloads.removeAtIndex(indexPath.row)
		DownloadManager.sharedManager.saveToDefaults()
		tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
	}
}

extension ListVideosVC: UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		player = downloads[indexPath.row].player

		try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
		let movieVC = AVPlayerViewController()
		movieVC.player = player
		self.presentViewController(movieVC, animated: true) { _ in
			movieVC.player?.play()
		}
	}
}
