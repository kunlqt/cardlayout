//
//  DiarySection.swift
//  cardLayout
//
//  Created by Kun Le on 10/29/20.
//  Copyright © 2020 Riley Norris. All rights reserved.
//

import Foundation
import RxDataSources

struct DiarySection: SectionModelType {
    
    typealias Item = Diary
    
    var items: [Diary]
    
    var diaryDate: String? {
        return items.first?.date
    }
}

extension DiarySection {
    
    init(original: DiarySection, items: [Diary]) {
        self = original
        self.items = items
    }
    
}
