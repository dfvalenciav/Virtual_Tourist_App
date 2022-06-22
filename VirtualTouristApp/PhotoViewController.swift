//
//  PhotoViewController.swift
//  VirtualTouristApp
//
//  Created by Daniel Felipe Valencia Rodriguez on 12/06/22.
//

import Foundation
import UIKit
import MapKit
import CoreData



class PhotoViewController : UIViewController {
    
    static let cellReuseIdentifier = "PhotoCellViewController"
    
    // MARK: - Properties
    var coordinate: CLLocationCoordinate2D?
    var images = [UIImage]()
    var pin : Pin!
    var dataController: dataController!
   
    // MARK: - IBOutlets
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var fetchingLabel: UILabel!
    
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate)
            .persistentContainer.viewContext
    
    var totalFlickrPhotosPages = 0
    var retreivePhotoDataTask: URLSessionDataTask? = nil
    var loadPhotosTasks: [URLSessionDataTask] = []
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var collectionViewCells: [PhotoCellViewController] = [] {
        didSet {
            debugPrint(
                "didSet collectionViewCells:\n" +
                "old count: \(oldValue.count), " +
                "new count: \(collectionViewCells.count)"
            )
        }
    }
    
    var isDownloadingImages = false {
        didSet {
            DispatchQueue.main.async {
                self.newCollectionButton.isEnabled =
                        !self.isDownloadingImages
            }
        }
    }
    
    
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        print("tapped new collection button")
        
        collectionViewCells = []
        collectionView.reloadData()
        retreivePhotoDataTask?.cancel()
        retreivePhotoDataTask = nil
        for task in loadPhotosTasks {
            task.cancel()
        }
        loadPhotosTasks = []
        let lowerBound = min(totalFlickrPhotosPages, 2)
        
        let upperBound = totalFlickrPhotosPages
        
        let newPage = Int.random(
            in: lowerBound...upperBound
        )
        
        print("getting Flickr photos for page", newPage)
        
        activityIndicator.startAnimating()
        isDownloadingImages = true
        let photos = fetchedResultsController?.fetchedObjects
        for photo in photos!{
            managedObjectContext.delete(photo)
        }
        retrievePhotoDataFromFlickr(page: newPage)
        saveContext()
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        fetchingLabel.isHidden = true
     }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("view will disappear")
    }
    
    func displayNoImagesLabel() {
        DispatchQueue.main.async {
            
            print("displayNoImagesLabel")
            self.activityIndicator.stopAnimating()
            self.fetchingLabel.isHidden = true
            self.isDownloadingImages = false
            let label = UILabel()
            label.frame = CGRect(
                x: 0, y: 0,
                width: self.view.frame.width/2 - 50,
                height: 300
            )
            label.center = self.view.center
            label.textAlignment = .center
            label.text = "No Images Found"
            label.textColor = .secondaryLabel
            label.font = .boldSystemFont(ofSize: 40)
            label.adjustsFontSizeToFitWidth = true
            self.view.addSubview(label)
            self.newCollectionButton.isHidden = true
            
        }
    }

    func setupFetchedResultsController() {
        guard let pin = pin else {
            fatalError("setupPhotos: pin is nil")
        }
        
        let fetchRequest: NSFetchRequest = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]
        
        self.fetchedResultsController = .init(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        do {
            try fetchedResultsController!.performFetch()
            
        } catch {
            print("fetchedResultsController couldn't fetch images")
        }

    }
    
    // MARK: Entry Point
    func setupPhotos() {
       
        self.loadViewIfNeeded()
        
        assert(collectionView != nil, "collection view is nil")
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        isDownloadingImages = true
        
        setupFetchedResultsController()

        // try to get photos associated with pin from core data
        let coreDataPhotos = fetchedResultsController?.fetchedObjects
        
        if let coreDataPhotos = coreDataPhotos, !coreDataPhotos.isEmpty {
            print(
                "setupPhotos: found \(coreDataPhotos.count) " +
                "photos in core data"
            )
            
            activityIndicator.stopAnimating()
            fetchingLabel.isHidden = true
            for (indx, photo) in coreDataPhotos.enumerated() {
                guard let uiImage = photo.image
                        .map(UIImage.init(data:)) as? UIImage
                else {
                    continue
                }
                
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: PhotoViewController.cellReuseIdentifier,
                    for: IndexPath(row: indx, section: 1)
                ) as! PhotoCellViewController
                
                cell.configure()
                cell.imageCell.image = uiImage
                cell.id = photo.id
                collectionViewCells.append(cell)
                collectionView.reloadData()
            }
            isDownloadingImages = false
            return
        }
        
    
        print("setupPhotos: retreiving photo data from Flickr")
        retrievePhotoDataFromFlickr(page: 0)
      
    }
    
    
    private func retrievePhotoDataFromFlickr(page: Int) {
        
        retreivePhotoDataTask = FlickrClient.shared.getFlickrPhotos(
            coordinate: pin!.coordinate,
            page: page
        ) { result in
            do {
                let photosData = try result.get()
                let photos = photosData.photos
                self.totalFlickrPhotosPages = photosData.totalPages
                if photos.isEmpty {
                    print("retrievePhotoDataFromFlickr: no photos found")
                    self.displayNoImagesLabel()
                }
                else {
                    print(
                        "retrievePhotoDataFromFlickr: " +
                        "retrieved \(photos.count) photos"
                    )
                    DispatchQueue.main.async {
                        self.loadPhotos(photos)
                    }
                    
                }
            } catch {
                self.displayNoImagesLabel()
                print("retrievePhotoDataFromFlickr error:\n\(error)")
            }
        }
    }

    private func loadPhotos(_ flickrPhotos: [FlickrReponse]) {

        print("func loadPhotos")
        
        activityIndicator.stopAnimating()
        var numberOfloadedPhotos = 0
        
        for (indx, flickrPhoto) in flickrPhotos.enumerated() {
            
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.cellReuseIdentifier,
                for: IndexPath(row: indx, section: 1)
            ) as! PhotoCellViewController
            
            cell.configure()
            cell.activityIndicatorCell.startAnimating()
            
            let task = flickrPhoto.retrievePhoto { result in
                do {
                    defer {
                        DispatchQueue.main.async {
                            cell.activityIndicatorCell.stopAnimating()
                            numberOfloadedPhotos += 1
                            if numberOfloadedPhotos == flickrPhotos.count {
                                self.isDownloadingImages = false
                                print("\n\nfinished downloading all photos\n\n")
                            }
                                
                        }
                    }
                    
                    let photo = try result.get()
                    let newCoreDataPhoto = Photo(
                        context: self.managedObjectContext
                    )
                    newCoreDataPhoto.pin = self.pin!
                    newCoreDataPhoto.image = photo.pngData()!
                    DispatchQueue.main.async {
                        cell.imageCell.image = photo
                        cell.id = newCoreDataPhoto.id
                    }
                    
                } catch {
                    
                    let nsError = error as NSError
                        
                    if nsError.code == NSURLErrorCancelled {
                        print(
                            "user cancelled loading photo for cell",
                            indx
                        )
                        return
                    }
                    
                    DispatchQueue.main.async {
                        //cell.couldntLoadImageLabel.isHidden = false
                    }
                    print("loadPhotos: error retreiving flickr photo:\n\(error)")
                }
            }
            saveContext()
            loadPhotosTasks.append(task)
            collectionViewCells.append(cell)
            collectionView.reloadData()
        }
        
        if collectionViewCells.isEmpty {
            DispatchQueue.main.async {
                self.displayNoImagesLabel()
            }
        }
    }
    
    private func saveContext() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
}

extension PhotoViewController: UICollectionViewDataSource {
    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        return 1
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        let number = collectionViewCells.count
        return number
        
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        return collectionViewCells[indexPath.row]
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        print("collectionView didSelectItemAt:", indexPath.row)
        if loadPhotosTasks.indices.contains(indexPath.row) {
            let removedTask = loadPhotosTasks.remove(at: indexPath.row)
            removedTask.cancel()
        }
        
        let removedCell = collectionViewCells.remove(at: indexPath.row)
        self.collectionView.deleteItems(at: [indexPath])
        
        guard let fetchedResultsController = fetchedResultsController else {
            print("no fetchedResultsController")
            return
        }
        for object in fetchedResultsController.fetchedObjects! {
            if object.id == removedCell.id {
                managedObjectContext.delete(object)
                saveContext()
            }
        }
    }
}

extension PhotoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let spacing: CGFloat = 3.5
        let dimension = ((view.frame.size.width) - (2 * spacing)) / spacing
        return CGSize(width: dimension, height: dimension)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        
        return UIEdgeInsets(
            top: 10,
            left: 10,
            bottom: 10,
            right: 10
        )
    }
}

