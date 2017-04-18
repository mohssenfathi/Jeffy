//
//  GIFManager.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 4/1/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit
import Alamofire
import Decodable
import Photos

class GIFManager: NSObject {
    
    static let shared = GIFManager()
    
    let cache = NSCache<AnyObject, AnyObject>()
    
    private let basePath = "http://api.giphy.com/v1/gifs/"
    private let apiKey = "dc6zaTOxFJmzC"
    
    func data(for gif: GIF, with type: GIFAsset.AssetType, completion: @escaping (Data?) -> ()) {
        
        if let data = cache.object(forKey: "\(gif.id)-\(type.rawValue)" as AnyObject) as? Data {
            completion(data)
            return
        }
        
        gif.asset(for: type)?.data { data in
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }
    
    func random(_ completion: @escaping (GIF?) -> ()) {
     
        let parameters = ["api_key" : apiKey, "rating": "g"];
        Alamofire.request(basePath + "random", parameters: parameters).responseJSON { response in
            guard let json = response.result.value else { return completion(nil) }
            guard let dict = json as? [AnyHashable : Any] else { return completion(nil) }
            var gif: GIF!
            do {
                gif = try GIF.decode(dict["data"] ?? [:])
            }
            catch {
                print(error.localizedDescription)
            }
            completion(gif)
        }
        
    }
    
    func search(keyword: String, count: Int = 25, offset: Int = 0, completion: @escaping ([GIF]) -> ()) {
        
        let parameters = [ "api_key" : apiKey,
                           "q" : keyword,
                           "rating" : "g",
                           "limit" : count,
        "offset" : offset ] as [String : Any]
        
        Alamofire.request(basePath + "search", parameters: parameters).responseJSON { response in
            
            guard let json = response.result.value as? [AnyHashable : Any] else { return }
            guard let dicts = json["data"] as? [Any] else { return completion([]) }
            
            var gifs = [GIF]()
            for dict in dicts {
                if let gif = try? GIF.decode(dict) {
                    gifs.append(gif)
                }
            }
            
            completion(gifs)

        }
    }
    
    func trending(count: Int = 25, offset: Int = 0, completion: @escaping ([GIF]) -> ()) {
        
        let parameters = [ "api_key" : apiKey,
                           "rating" : "g",
                           "limit" : count,
                           "offset" : offset ] as [String : Any]
        
        Alamofire.request(basePath + "trending", parameters: parameters).responseJSON { response in
            
            guard let json = response.result.value as? [AnyHashable : Any] else { return }
            guard let dicts = json["data"] as? [Any] else { return completion([]) }
            
            var gifs = [GIF]()
            for dict in dicts {
                if let gif = try? GIF.decode(dict) {
                    gifs.append(gif)
                }
            }
            
            completion(gifs)
            
        }
    }
    
    // Exporting
//    var pendingExport: PendingExport?
//    var exportTimer: Timer?
}

//struct PendingExport {
//    var livePhoto: PHLivePhoto?
//    var urls: (String, String)?
//    var gif: GIF?
//    var completion: ((Bool, Error?) -> ())?
//}


// MARK: - Exporting
extension GIFManager {
    
    // Since the get live photo completion block is called multiple times, we update each time it is called,
    // then only export once its been 3.0 seconds since the last callback

//    func exportTimerFired() {
//        
//        if let export = pendingExport, let livePhoto = export.livePhoto {
//            
//            guard let urls = export.urls else {
//                export.completion?(false, nil)
//                return
//            }
//            
//            export.livePhoto = nil
//            
//            guard let photoURL = URL(string: urls.0), let videoURL = URL(string: urls.1) else {
//                export.completion?(false, nil)
//                return
//            }
//            
//            PhotosManager.shared.save(livePhoto: livePhoto, with: , photoURL: photoURL, videoURL: videoURL, completion: { (success, error) in
//                DispatchQueue.main.async {
//                    export.completion?(success, error)
//                }
//            })
//            
//            
//        } else {
//            pendingExportCompletion?(false, nil)
//        }
//    }
    
    func exportLivePhoto(for gif: GIF, completion: @escaping (Bool, Error?) -> ()) {
        
        gif.livePhoto { livePhoto, info, urls in

            guard let urls = urls, let livePhoto = livePhoto else { return }
            guard let photoURL = URL(string: urls.0), let videoURL = URL(string: urls.1) else {
                completion(false, nil)
                return
            }
            
            PhotosManager.shared.save(livePhoto: livePhoto, with: gif.id, photoURL: photoURL, videoURL: videoURL, completion: completion)
            
//            self.pendingExport = PendingExport()
//            self.pendingExport?.livePhoto = livePhoto
//            self.pendingExport?.url? = urls
//            self.pendingExport?.completion = completion
//            self
//            
//            self.exportTimer?.invalidate()
//            self.exportTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self,
//                                                    selector: #selector(self.exportTimerFired),
//                                                    userInfo: nil, repeats: false)
        }
    }
}
