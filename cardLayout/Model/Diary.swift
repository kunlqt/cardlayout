//
//  Diary.swift
//  cardLayout
//
//  Created by Kun Le on 10/27/20.
//  Copyright © 2020 Riley Norris. All rights reserved.
//

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
