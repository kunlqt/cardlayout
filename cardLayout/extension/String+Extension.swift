//
//  String+Extension.swift
//  Diary
//
//  Created by Lucio on 9/22/20.
//  Copyright © 2020 Lucio. All rights reserved.
//

import Foundation

enum DiaryDateFormat {
    case dayFormat
    case timeFormat
    case fullFormat
    
    var format: String {
        switch self {
        case .dayFormat:
            return "yyyy-MM-dd"
        case .timeFormat:
            return "HH:mm:ss"
        case .fullFormat:
            return "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        }
    }
}

extension String {
    
    func toStringDate(get format: String = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", diaryFormat: DiaryDateFormat) -> String? {
       let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = format

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = diaryFormat.format
            
        guard let date = dateFormatterGet.date(from: self) else {
            return nil
        }
        
        return dateFormatter.string(from: date)
    }
    
    func toDate(_ format: String = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self)
    }
    
}
