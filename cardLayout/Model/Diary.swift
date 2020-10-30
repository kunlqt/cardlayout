import Foundation

struct Diary: Codable {
  let id: String
  var content: String
  var title: String
  let date: String

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case content
    case date
  }
}
