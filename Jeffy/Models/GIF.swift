//
//  GIF.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 4/1/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import Decodable
import Photos

struct GIF: Decodable {
    
    var id: String!
    var url: String?
    var imageURL: String?
    var hasBeenSaved: Bool = false
    var assets: [GIFAsset.AssetType : GIFAsset]?
//    var imageURL_mp4: String?
//    var numberOfFrames: Int = 0
//    var size: CGSize = .zero
//    var username: String?
//    var caption: String?
//    var rating: String?
    
    func asset(for type: GIFAsset.AssetType) -> GIFAsset? {
        return assets?[type]
    }
}

struct GIFAsset: Decodable {
    
    enum AssetType: String {
        case original = "original"
        case preview = "preview_gif"
        case small = "downsized"
        case medium = "downsized_medium"
        case large = "downsized_large"
        case fixedWidth = "fixed_width"
        case fixedHeight = "fixed_height"
        case unknown = "unknown"
        
        static func allTypes() -> [AssetType] {
            return [.original, .preview, .small, .medium, .large, .fixedWidth, .fixedHeight]
        }
    }
    
    var type: AssetType = .unknown
    var height: Int?
    var width: Int?
    var url: String?
    
    static func decode(_ json: Any) throws -> GIFAsset {
        return GIFAsset(
            type: .unknown,
            height: try Int(json => "height"),
            width: try Int(json => "width"),
            url: try json => "url")
    }
}

extension GIF {
    
    static func decode(_ json: Any) throws -> GIF {
        
        let decodeAssets = { () -> [GIFAsset.AssetType : GIFAsset] in
            
            guard let assetDicts = try json => "images" as? [String: Any] else { return [:] }
            var assets = Dictionary<GIFAsset.AssetType, GIFAsset>()

            for type in GIFAsset.AssetType.allTypes() {
                if let dict = assetDicts[type.rawValue] as? [String : Any] {
                    
                    var asset: GIFAsset?
                    do {
                        asset = try GIFAsset.decode(dict)
                        asset?.type = type
                        assets[type] = asset
                    }
                    catch {
                        print(error.localizedDescription)
                    }
//                    if var asset = try? GIFAsset.decode(dict) {
//                        asset.type = type
//                        assets[type] = asset
//                    }
                }
            }
            
            return assets
        }
        
        return GIF(
            id: try json => "id",
            url: try json => "url",
            imageURL: try (json =>? "image_url"),
            hasBeenSaved: false,
            assets: try? decodeAssets()
            
//            imageURL_mp4: try json => "image_mp4_url",
//            numberOfFrames: 0, // try json => "image_frames" ?? 0,
//            size: .zero, // CGSize(width: try json => "image_width", height: try json => "image_height"),
//            username: try json => "username",
//            caption: try json => "caption",
//            rating: try json => "rating"
        )
    }
}

extension GIF {
    
    func livePhoto(_ completion: @escaping (PHLivePhoto?, [AnyHashable : Any]?, (String, String)?) -> ()) {
        
        DispatchQueue.global(qos: .background).async {
            
            self.mov { url in
                
                guard let url = url else { return completion(nil, nil, nil) }
                let asset = AVURLAsset(url: url)
                
                PhotosManager.shared.livePhoto(from: asset, completion: { (livePhoto, info, urls) in
                    DispatchQueue.main.async {
                        completion(livePhoto, info, urls)
                    }
                })
            }
        }
        
    }
    
    func data(_ completion: @escaping (Data?) -> ()) {
        
        var url = imageURL
        if url == nil {
            guard let gifAsset = asset(for: .original) ?? asset(for: .large) else { return completion(nil) }
            url = gifAsset.url
        }
        
        guard url != nil else { return completion(nil) }
        
        Alamofire.request(url!).responseData { response in
            DispatchQueue.main.async { completion(response.result.value) }
        }
    }

    func mov(_ completion: @escaping (URL?) -> ()) {
        
        data { d in
            
            guard let d = d else { return completion(nil) }
            
            let id = self.id ?? "tmp"
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(id).mov")
            
            GIFConverter(data: d)?.convertAndExport(to: url, completion: {
                completion(url)
            })
        }
        
    }
}

extension GIFAsset {
    
    func data(_ completion: @escaping (Data?) -> ()) {
        
        guard let url = url else { return completion(nil) }
        
        Alamofire.request(url).responseData { response in
            DispatchQueue.main.async { completion(response.result.value) }
        }
    }
    
}
