//
//  UIViewController.swift
//  VirtualTouristApp
//
//  Created by Daniel Felipe Valencia Rodriguez on 10/06/22.
//

import Foundation
import UIKit
import MapKit

extension UIViewController {
    func buttonEnabled(_ enabled: Bool, button: UIButton) {
        if enabled {
            button.isEnabled = true
            
        } else {
            
            button.isEnabled = false
        }
    }
    
    func showAlert(message: String, title: String) {
        let alertVC = UIAlertController (title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true)
}
    
    //open links
    
    func openLink(_ url: String) {
        guard let url = URL(string: url), UIApplication.shared.canOpenURL(url)
            else {
                showAlert(message: "Cannot open link", title: "Invalid URL")
                return
        }
}
    
    func showFailure(title: String, message: String) {
        let alert = UIAlertController(title: "ALERT", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
        NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func zoomInMap(mapView: MKMapView, coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
}
