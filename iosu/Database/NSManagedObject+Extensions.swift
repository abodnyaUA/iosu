//
//  NSManagedObject+Extensions.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/14/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        let entityName = type(of: self).entity().name
        let describingName = String(describing: type(of: self).classForCoder())
        let name = entityName ?? describingName
        let entityDescription = NSEntityDescription.entity(forEntityName: name, in: context)!
        self.init(entity: entityDescription, insertInto: context)
    }
}
