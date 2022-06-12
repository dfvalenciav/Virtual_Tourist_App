//
//  ViewController.swift
//  VirtualTouristApp
//
//  Created by Daniel Felipe Valencia Rodriguez on 7/06/22.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var initialLatitude : Double = 4.624335
    var initialLongitude : Double = -74.063644
    var annotations = [MKPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        mapView.delegate = self
        mapView.addGestureRecognizer(longTapGesture)
       // showMapAnnotations()
    }
    
    @objc func longTap (sender: UIGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: self.mapView)
            let touchMapCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation2 = MKPointAnnotation()
            annotation2.coordinate = touchMapCoordinate
            annotation2.subtitle = "Long: " + String(touchMapCoordinate.longitude)
            annotation2.title = "Lat: " + String( touchMapCoordinate.latitude)
            annotations.append(annotation2)
            self.mapView.addAnnotations(annotations)
        }
    }
    
   func showMapAnnotations () {
        let latitude = CLLocationDegrees(initialLatitude)
        let longitude = CLLocationDegrees(initialLongitude)
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation ()
        annotation.coordinate = coordinate
        annotation.title = "Colombia"
        annotation.subtitle = "Bogotá"
        annotations.append(annotation)
        self.mapView.addAnnotations(annotations)
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
    
   func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let url = URL(string: (view.annotation?.subtitle!)!)
            if  !verifyUrl(urlString: view.annotation?.subtitle!) {
                self.showFailure(message: "Invalid URL!")
            } else {
                UIApplication.shared.open(url! as URL, options: [:], completionHandler: nil)
            }
        }
    }
    func verifyUrl(urlString: String?) -> Bool {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return false
        }

        return UIApplication.shared.canOpenURL(url)
    }
}

