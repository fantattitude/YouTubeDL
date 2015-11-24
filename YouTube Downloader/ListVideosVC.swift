import UIKit
import AVFoundation
import AVKit

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
	var sounds = [String]()

	func refreshData() {
		let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]

		guard let files = try? NSFileManager.defaultManager().contentsOfDirectoryAtPath(path) else { return }
		sounds = files.map { path + "/" + $0 }

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
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sounds.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = UITableViewCell()
		cell.textLabel?.lineBreakMode = .ByTruncatingMiddle
		cell.textLabel?.text = sounds[indexPath.row]
		return cell
	}
}

extension ListVideosVC: UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let sound = sounds[indexPath.row]

		if (sound as NSString).pathExtension == "m4a" {
			let composition = AVMutableComposition()

			let audioURL = NSURL(fileURLWithPath: sound)
			let audioAsset = AVURLAsset(URL: audioURL)
			let audioTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(audioAsset.duration.value - (audioAsset.duration.value / 2), audioAsset.duration.timescale))

			let bCompositionAudioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
			try! bCompositionAudioTrack.insertTimeRange(audioTimeRange, ofTrack: audioAsset.tracksWithMediaType(AVMediaTypeAudio)[0], atTime: kCMTimeZero)

			let videoURL = NSURL(fileURLWithPath: (sound as NSString).stringByDeletingPathExtension + ".mp4")
			let videoAsset = AVURLAsset(URL: videoURL)
			let videoTimeRange = audioTimeRange

			//Now we are creating the second AVMutableCompositionTrack containing our video and add it to our AVMutableComposition object.
			let aCompositionVideoTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
			try! aCompositionVideoTrack.insertTimeRange(videoTimeRange, ofTrack: videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: kCMTimeZero)

			let playerItem = AVPlayerItem(asset: composition)
			player = AVPlayer(playerItem: playerItem)
		} else {
			player = AVPlayer(URL: NSURL(fileURLWithPath: sounds[indexPath.row]))
		}

		try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
		let movieVC = AVPlayerViewController()
		movieVC.player = player
		self.presentViewController(movieVC, animated: true, completion: nil)
	}
}
