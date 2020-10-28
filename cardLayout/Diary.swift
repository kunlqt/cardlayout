//
//  Diary.swift
//  cardLayout
//
//  Created by Kun Le on 10/7/20.
//  Copyright © 2020 Riley Norris. All rights reserved.
//

import Foundation
struct Diary: Codable {
    let id: Int
    let title: String
    let content: String
    let date: String

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case content
    case date
  }
}
