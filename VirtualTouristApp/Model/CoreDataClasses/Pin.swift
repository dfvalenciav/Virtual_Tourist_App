//
//  Pin.swift
//  VirtualTouristApp
//
//  Created by Daniel Felipe Valencia Rodriguez on 20/06/22.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)
public class Pin: NSManagedObject {

    var coordinate: CLLocationCoordinate2D {
        get {
            return .init(latitude: coreLatitude, longitude: coreLongitude)
        }
        set {
            self.coreLatitude = newValue.latitude
            self.coreLongitude = newValue.longitude
        }
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.creationDate = Date()
    }
}
