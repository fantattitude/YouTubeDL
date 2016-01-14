import UIKit

class VideoCell: UITableViewCell {
	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var rightDetail: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
	@IBOutlet weak var thumbImageView: UIImageView!
	@IBOutlet weak var qualityLabel: UILabel!

	func configureWithDownload(download: Download) {
		selectionStyle = download.status == .Downloading ? .None : .Default
		title.text = download.name
		rightDetail.text = download.videoLength
		qualityLabel.text = download.quality.stringValue
		thumbImageView.image = download.thumbnail
	}
}