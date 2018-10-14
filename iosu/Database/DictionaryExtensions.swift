//
//  DictionaryExtensions.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/14/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import Foundation

extension Array {
    
    func dictionary(map: (_ object: Iterator.Element) -> String) -> [String: Iterator.Element] {
        var result = [String: Element]()
        for obj in self {
            let key = map(obj)
            result[key] = obj
        }
        return result
    }
}
