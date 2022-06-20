//
//  ViewController.swift
//  VirtualTouristApp
//
//  Created by Daniel Felipe Valencia Rodriguez on 7/06/22.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController:UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var pins = [Pin]()
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var pinLong:Double = 0.0
    var pinLat:Double = 0.0
    var annotations = [MKPointAnnotation]()
    
    let defaults = UserDefaults.standard
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        longTapGesture.minimumPressDuration = 0.5
        mapView.delegate = self
        mapView.addGestureRecognizer(longTapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
       // zoomToLastLocation()
        fetchPinsFromCoreData()
    }
    
    func fetchPinsFromCoreData () {
        do {
            pins = try context.fetch(Pin.fetchRequest())
            for pin in pins {
                let latitude = CLLocationDegrees(pin.coreLatitude)
                let longitude = CLLocationDegrees(pin.coreLongitude)
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
            }
            self.mapView.addAnnotations(annotations)
        }catch {
            self.showFailure(title: "Core Data Error", message: "Unable to fetch locations")
        }
    }
    
    @objc func longTap (sender: UIGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: self.mapView)
            let touchMapCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let latitude = CLLocationDegrees(touchMapCoordinate.latitude)
            let longitude = CLLocationDegrees(touchMapCoordinate.longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchMapCoordinate
            annotations.append(annotation)
            self.mapView.addAnnotations(annotations)
            savePinToUserDefaults (lat : latitude, long : longitude)
            savePinToCoreData (lat : latitude, long : longitude)
            fetchPinsFromCoreData()
            zoomToLastLocation()
        }
    }
    
    func savePinToUserDefaults(lat: Double, long: Double) {
        defaults.set(lat, forKey: "latitude")
        defaults.set(long, forKey: "longitude")
    }
    
   func savePinToCoreData (lat : Double, long: Double) {
       guard let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) else { return }
       let pin = NSManagedObject(entity: entity, insertInto: context)
       pin.setValue(lat, forKey: "coreLatitude")
       pin.setValue(long, forKey: "coreLongitude")
       do {
           try context.save()
       } catch let error {
           showFailure(title: "Unable to save location.", message: error.localizedDescription)
       }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier:reuseId)
            pinView!.canShowCallout = true
            pinView!.markerTintColor = .black
            pinView?.rightCalloutAccessoryView = UIButton(type: .infoDark)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        let currentCoordinate = view.annotation!.coordinate
       guard let selectedPin = self.pins.first(where: { pin in
            pin.coordinate == currentCoordinate
        })else {
            showFailure(title: "Error Coordinate", message: "mapView didSelect view: could not get pin for coordinate")
            return
        }
        let controller = self.storyboard!.instantiateViewController(
            identifier: "PhotoViewController"
        ) as! PhotoViewController
        controller.pin = selectedPin
        controller.setupPhotos()
        self.show(controller, sender: self)
    }
    
    func getPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> Pin? {
        for pin in pins {
            if (pin.coreLatitude == latitude && pin.coreLongitude == longitude) {
                return pin
            }
        }
        return nil
    }
    
    func zoomToLastLocation() {
        guard let latitude = defaults.object(forKey: "latitude") as? Double else { return }
        guard let longitude = defaults.object(forKey: "longitude") as? Double else { return }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        zoomInMap(mapView: mapView, coordinate: coordinate)
    }
}

