//
//  Photo.swift
//  VirtualTouristApp
//
//  Created by Daniel Felipe Valencia Rodriguez on 20/06/22.
//

import Foundation
import CoreData
import UIKit

@objc(Photo)
public class Photo: NSManagedObject {

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.creationDate = Date()
        self.id = UUID()
    }
}
