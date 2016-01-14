import UIKit
import AVFoundation
import AVKit

class ListVideosVC: UIViewController {
	var refreshControl: UIRefreshControl!

	@IBOutlet private weak var tableView: UITableView! {
		didSet {
			refreshControl = UIRefreshControl()
			refreshControl.addTarget(self, action: "refreshData", forControlEvents: .ValueChanged)
			tableView.insertSubview(refreshControl, atIndex: 0)
		}
	}
	var player: AVPlayer?
	var downloads: [[Download]] {
		return [DownloadManager.sharedManager.downloading, DownloadManager.sharedManager.readyDownload]
	}

	let notificationManager = NotificationManager()

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

	func refreshData() {
		if DownloadManager.sharedManager.downloads.isEmpty {
			DownloadManager.sharedManager.loadFromDefaults()
		}

		navigationItem.title = "YouTube ⬇\u{0000FE0E}"

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
		notificationManager.registerObserver(AVPlayerItemDidPlayToEndTimeNotification, block: videoDidFinishPlaying)
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
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 2
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return downloads[section].count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("VideoCell", forIndexPath: indexPath) as! VideoCell

		cell.configureWithDownload(downloads[indexPath.section][indexPath.row])

		return cell
	}

	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		guard editingStyle == .Delete else { return }

		DownloadManager.sharedManager.downloads.removeAtIndex(indexPath.row)
		DownloadManager.sharedManager.saveToDefaults()
		tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
	}

	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return "Downloading"
		case 1:
			return "Ready"
		default:
			return nil
		}
	}
}

extension ListVideosVC: UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let download = downloads[indexPath.section][indexPath.row]

		guard download.status == .ReadyToPlay else { return }

		player = download.player

		try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
		let movieVC = AVPlayerViewController()
		movieVC.player = player
		presentViewController(movieVC, animated: true) { _ in
			movieVC.player?.play()
		}
	}
}

extension ListVideosVC {
	func videoDidFinishPlaying(notification: NSNotification!) {
		dismissViewController()
	}
}
