//
//  PhotosManager.swift
//  Lumen
//
//  Created by Mohssen Fathi on 4/23/16.
//  Copyright © 2016 mohssenfathi. All rights reserved.
//

import UIKit
import Photos

class PhotosManager: NSObject {

    static let shared = PhotosManager()
    var requestIds = [PHImageRequestID]()
  
//  MARK: - Authorization
    
    func authorizationStatus() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }
    
    func requestAuthorization(completion: ((PHAuthorizationStatus) -> ())?) {
        
        PHPhotoLibrary.requestAuthorization { (status) in
            completion?(status)
        }
        
    }
    
//  MARK: - Saving
    func saveToTileAlbum(_ photo: UIImage) {
        JeffyAlbum.sharedInstance.savePhoto(photo)
    }
    
    
//  MARK: - Fetch
    
    func tileAssets(completion: @escaping (_ assets: [PHAsset]) -> ()) {
    
        JeffyAlbum.sharedInstance.loadJeffyAlbum { (collection) in
            if collection == nil {
                completion([])
                return
            }
            completion(self.assets(collection!))
        }
    
    }
    
    var collections: [PHAssetCollection] {
        get {
            var allCollections = [PHAssetCollection]()
            
            let options = PHFetchOptions()
            var type = PHAssetCollectionType.smartAlbum
            var subtype = PHAssetCollectionSubtype.smartAlbumUserLibrary
            var fetchResult: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: options)
            
            for i in 0 ..< fetchResult.count {
                allCollections.append(fetchResult.object(at: i))
            }
            
            options.predicate = NSPredicate(format: "estimatedAssetCount > %d", 0)
            type = PHAssetCollectionType.album
            subtype = PHAssetCollectionSubtype.any
            fetchResult = PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: options)
            fetchResult.enumerateObjects({ (collection, index, stop) in
                if self.shouldIncludeCollection(collection) {
                    allCollections.append(collection)
                }
            })
            
            return allCollections
        }
    }
    
    func shouldIncludeCollection(_ collection: PHAssetCollection) -> Bool {
        if collection.localizedTitle == "slo-mo" { return false }
        if collection.localizedTitle == "videos" { return false }
        if collection.localizedTitle == "recently deleted" { return false }
        
        let listResult = PHCollectionList.fetchCollectionListsContaining(collection, options: nil)
        
        if listResult.count == 0 { return true }
        let collectionList = listResult.firstObject! as PHCollectionList
        if collectionList.localizedTitle?.lowercased() == "iphoto events" {
            return false
        }
    
        return true
    }
    
    
    func assets(_ collection: PHAssetCollection) -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        
        var allObjects = [PHAsset]()
        for i in 0 ..< fetchResult.count {
            allObjects.append(fetchResult.object(at: i))
        }
        
        return allObjects
    }
    
    var allAssets: [PHAsset] {
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        
        var allObjects = [PHAsset]()
        for i in 0 ..< fetchResult.count {
            allObjects.append(fetchResult.object(at: i))
        }
        
        return allObjects
    }
    
    
    var livePhotos: [PHAsset] {
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaSubtype == %ld", PHAssetMediaSubtype.photoLive.rawValue)

        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        
        var allObjects = [PHAsset]()
        for i in 0 ..< fetchResult.count {
            allObjects.append(fetchResult.object(at: i))
        }
        
        return allObjects
    }
    
    func livePhoto(for asset: PHAsset, completion: @escaping ((PHLivePhoto?, [AnyHashable : Any]?) -> ())) {
        
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, _, _, _ in
            
            DispatchQueue.main.sync {
                //self.progressView.progress = Float(progress)
            }
        }
        
        let targetSize = PHImageManagerMaximumSize
        
        PHImageManager.default().requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { livePhoto, info in
            completion(livePhoto, info)
        })
    }

    fileprivate var faceAssets = [PHAsset]()
    var isLoadingFaces: Bool = false
    
    func faceAssets(callbackCount: Int = 100, completion: @escaping (([PHAsset]) ->())) {

        /*
            Need to save lost of asset identifiers in core data later
         */
        
        isLoadingFaces = true
        
        var faces = [PHAsset]()
        
        guard let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow]) else {
            isLoadingFaces = false
            completion(faces)
            return
        }
        
        let manager = PHImageManager.default()
        
        let initialRequestOptions = PHImageRequestOptions()
        initialRequestOptions.isSynchronous = true
        initialRequestOptions.resizeMode = .fast
        initialRequestOptions.deliveryMode = .fastFormat

        DispatchQueue.global(qos: .background).async {
            
            for asset in self.allAssets {
                
                manager.requestImage(for: asset, targetSize: CGSize(width: 50, height: 50), contentMode: .aspectFit, options: initialRequestOptions, resultHandler: { (image, info) in
                    
                    guard let image = image, let ciImage = CIImage(image: image) else { return }
                    
                    let features = detector.features(in: ciImage)
                    if features.count > 0 {
                        faces.append(asset)
                        
                        if faces.count % callbackCount == 0 {
                            
                            DispatchQueue.main.async { completion(faces) }
                            
                        }
                    }
                })
            }
        
            self.isLoadingFaces = false
            DispatchQueue.main.async { completion(faces) }
        }
        
        //                    var rect = CGRectZero
        //                    features.forEach {
        //                        rect.unionInPlace($0.bounds)
        //                    }
        //
        //                    let transform = CGAffineTransformMakeScale(1.0 / initialResult!.size.width, 1.0 / initialResult!.size.height)
        //                    finalRequestOptions.normalizedCropRect = CGRectApplyAffineTransform(rect, transform)
    }

    
    lazy var allAssetsCollection: PHAssetCollection? = {
        
        // Will this work in other countries?
        return self.collections.filter { $0.localizedTitle?.lowercased() == "all photos" }.first
    }()
    
    
//   MARK: - Images
    func imageForAsset(_ asset: PHAsset,
                       size:CGSize?,
                       progress: PHAssetImageProgressHandler?,
                       completion:@escaping (_ resultImage: UIImage?) -> Void) {
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.progressHandler = progress
        
        let size = size ?? PHImageManagerMaximumSize
        
        let requestId = PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { (resultImage, _) in
            DispatchQueue.main.async(execute: {
                completion(resultImage)
            })
        }
        
        requestIds.append(requestId)
    }
    
    func cancelAllRequests() {
        for requestId in requestIds {
            PHImageManager.default().cancelImageRequest(requestId)
        }
    }
    
    func imageForCollection(_ collection: PHAssetCollection, size:CGSize?, completion:@escaping (_ resultImage: UIImage?) -> Void) {
        guard let asset = assets(collection).last else {
            completion(nil)
            return
        }
    
        self.imageForAsset(asset, size: size, progress: nil) { (resultImage) in
            completion(resultImage)
        }
    }

    
    // Live Photos
    var savedLivePhotoIdentifiers = [String : PHAsset]()
}

//extension PHFetchResult where ObjectType is PHAsset {
//    func allObjects() -> [PHAsset] {
//        let range = NSRange(location: 0, length: self.count)
//        let objects = self.objects(at: IndexSet(integersIn: range.toRange() ?? 0..<0))
//        return objects
//    }
//}


// MARK: - Live Photos
extension PhotosManager {
    
    func image(from asset: AVURLAsset, at time: CMTime) -> UIImage? {
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        guard let imageRef = try? imageGenerator.copyCGImage(at: time, actualTime: nil) else { return nil }
        return UIImage(cgImage: imageRef)
    }
    
    func livePhoto(from asset: AVURLAsset, completion: @escaping ((PHLivePhoto?, [AnyHashable: Any]?, (String, String)) -> ())) {
        
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else { return }
        
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else { return }
        
        let assetIdentifier = UUID().uuidString
        let basename = "LivePhoto-\(assetIdentifier)"
        
        let imagePath = documentsUrl.appendingPathComponent("\(basename).JPG").path
        let moviePath = documentsUrl.appendingPathComponent("\(basename).MOV").path
        
        let tmpImagePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(basename).tiff").path
        let tmpMoviePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(basename).mov").path
        
        for path in [imagePath, moviePath, tmpImagePath, tmpMoviePath] {
            if FileManager.default.fileExists(atPath: path) {
                do { try FileManager.default.removeItem(at: URL(fileURLWithPath: path)) }
                catch { /* Blah */ }
            }
        }
        
        guard let image = image(from: asset, at: CMTime(seconds: 1, preferredTimescale: 60)) else { return }
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        guard let _ = try? imageData?.write(to: URL(fileURLWithPath: tmpImagePath), options: [.atomic]) else { return }
        
        session.outputFileType = "com.apple.quicktime-movie"
        session.outputURL = URL(fileURLWithPath: tmpMoviePath)
        session.timeRange = CMTimeRange(start: kCMTimeZero, end: asset.duration)
        
        session.exportAsynchronously {
            
            DispatchQueue.main.async {
                
                switch session.status {
                case .completed:
                    JPEG(path: tmpImagePath).write(imagePath, assetIdentifier: assetIdentifier)
                    QuickTimeMov(path: tmpMoviePath).write(moviePath, assetIdentifier: assetIdentifier)
                    
                    let urls: [URL] = [URL(fileURLWithPath: moviePath), URL(fileURLWithPath: imagePath)]
                    
                    PHLivePhoto.request(withResourceFileURLs: urls, placeholderImage: image, targetSize: .zero, contentMode: .aspectFit) {
                        (livePhoto, info) in
                        completion(livePhoto, info, (imagePath, moviePath))
                    }
                    
                case .cancelled, .exporting, .failed, .unknown, .waiting:
                    print("Problem exporting assets: \(session.status) - \(session.error?.localizedDescription ?? "")")
                }
                
                for path in [tmpImagePath, tmpMoviePath] {
                    let _ = try? FileManager.default.removeItem(atPath: path)
                }
            }
        }
        
    }
    
    func save(livePhoto: PHLivePhoto, with identifier: String, photoURL: URL, videoURL: URL, completion: @escaping (Bool, Error?) -> ()) {
        
        
        let save = {
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, fileURL: photoURL, options: nil)
                request.addResource(with: .pairedVideo, fileURL: videoURL, options: nil)
            }) { (success, error) in
                // TODO: -
                //            _ = try? FileManager.default.removeItem(at: url)
                if let asset = self.livePhotos.last {
                    self.savedLivePhotoIdentifiers[identifier] = asset
                }
                completion(success, error)
            }

        }
        
//        if let asset = self.savedLivePhotoIdentifiers[identifier] {
//
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.deleteAssets([asset] as NSFastEnumeration)
//            }) { (success, error) in
//                save()
//            }
//            
//        } else {
            save()
//        }

    }
}
