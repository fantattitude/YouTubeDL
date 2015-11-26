import Foundation

protocol Encodable {
	func encode() -> NSDictionary
	init?(dictionaryRepresentation: NSDictionary?)
}