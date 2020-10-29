import Foundation

struct Diary: Codable {
  let id: String
  var content: String
  var title: String
  let date: String

  var dayDate: String? {
    self.formatDate(.dayFormat)
  }
    private func formatDate(_ diaryFormat: DiaryDateFormat) -> String? {
//        guard let date = self.date else { return nil }
         
        return self.date.replacingOccurrences(of: "Z", with: "").toStringDate(diaryFormat: diaryFormat)
    }
  enum CodingKeys: String, CodingKey {
    case id
    case title
    case content
    case date
  }
}
