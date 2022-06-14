//
//  FlickrClient.swift
//  VirtualTouristApp
//
//  Created by Daniel Felipe Valencia Rodriguez on 12/06/22.
//

import Foundation
import CoreLocation
import UIKit

class FlickrClient {
    static let Key = "086bb4e9237031ab922da8ffe54feb5f"
    
    enum endPoints {
        static let base = "https://www.flickr.com/services/rest/?method=flickr.photos.search"
        static let apikey = "&api_key=" + Key
        
        case fetchImages(Double, Double)
        
        var stringValue : String {
            switch self {
            case .fetchImages(let lat, let long): return endPoints.base + endPoints.apikey + "&lat=\(lat)" + "&lon=\(long)" + "&format=json&nojsoncallback=1&extras=url_m"
            }
        }
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    func fetchResults (forCoordinate coordinate : CLLocationCoordinate2D, completion : @escaping (Result<[Photograph], Error>) -> Void ) {
        let url = endPoints.fetchImages(coordinate.latitude, coordinate.longitude).url
        let task = URLSession.shared.dataTask(with: url) {data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
            guard let data = data else {
                return
            }
            let decoder = JSONDecoder()
            do{
                let result = try decoder.decode(FlickrReponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(result.photos.photo))
                }
            }catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    func downloadImage (forPhotograph photograph : Photograph, completion : @escaping (Result<UIImage, Error>) -> Void ) {
        let serverId = photograph.server
        let id = photograph.id
        let secret = photograph.secret
        let urlString = "https://live.staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
        guard let url = URL(string: urlString) else {return}
        do {
            let data = try Data(contentsOf: url)
            guard let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                completion(.success(image))
            }
        }catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
        
    }
}
