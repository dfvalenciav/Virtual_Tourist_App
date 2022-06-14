//
//  FlickrResponse.swift
//  VirtualTouristApp
//
//  Created by Daniel Felipe Valencia Rodriguez on 12/06/22.
//

import Foundation

struct FlickrReponse: Codable {
    let photos: Photographs
    let stat: String
}

struct Photographs: Codable {
    let page, pages, perpage, total: Int
    let photo: [Photograph]
}

struct Photograph: Codable {
    let id, owner, secret, server: String
}
