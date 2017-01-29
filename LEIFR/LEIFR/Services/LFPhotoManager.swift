//
//  LFPhotoManager.swift
//  LEIFR
//
//  Created by Jinghan Wang on 29/1/17.
//  Copyright © 2017 Echx. All rights reserved.
//

import UIKit
import Photos

class LFPhotoManager: NSObject {
	static let shared = LFPhotoManager()
	let thumbnailSize = CGSize(width: 200, height: 200)
	
	func fetchAssets(from fromDate: Date, till endDate: Date) -> PHFetchResult<PHAsset> {
		let fetchOptions = PHFetchOptions()
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
		fetchOptions.predicate = NSPredicate(format: "(creationDate >= %@) AND (creationDate <= %@) AND (mediaType == %ld)", fromDate as NSDate, endDate as NSDate, PHAssetMediaType.image.rawValue)
		let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
		return fetchResult
	}
	
	func getImageForAsset(asset: PHAsset, size: CGSize, completion: @escaping ((UIImage?) -> Void)) {
		let manager = PHCachingImageManager.default()
		let options = PHImageRequestOptions()
		options.resizeMode = .exact
		options.deliveryMode = .opportunistic
		manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options, resultHandler: {
			(result, _) in
			completion(result);
		})
	}
}

extension PHAsset {
	func thumbnail(completion: @escaping ((UIImage?) -> Void)) {
		let manager = LFPhotoManager.shared
		manager.getImageForAsset(asset: self, size: manager.thumbnailSize, completion: completion)
	}
}
