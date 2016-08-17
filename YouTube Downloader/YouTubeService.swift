import Foundation
import XCDYouTubeKit
import RxSwift
import RxCocoa

class YouTubeVideo {
	init(_: XCDYouTubeVideo) {

	}
}

protocol YouTubeService {
	func retrieveVideoInfo(identifier: String) -> Observable<YouTubeVideo>
	func downloadVideo(video: YouTubeVideo) -> Observable<YouTubeVideo>
}