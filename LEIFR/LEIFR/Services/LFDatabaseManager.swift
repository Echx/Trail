//
//  LFDatabaseManager.swift
//  LEIFR
//
//  Created by Jinghan Wang on 12/9/16.
//  Copyright © 2016 Echx. All rights reserved.
//

import UIKit
import MapKit

class LFDatabaseManager: NSObject {
	private static let manager = LFDatabaseManager()
	private var databaseQueue: FMDatabaseQueue!
	var database: FMDatabase!
	
	class func sharedManager() -> LFDatabaseManager {
		return self.manager
	}
	
	func createDatabaseIfNotExist(name: String) {
		let databaseDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
		let destinationPath = databaseDirectory.stringByAppendingString("/\(name).sqlite")
		let fileManager = NSFileManager.defaultManager()
		
		if !fileManager.fileExistsAtPath(destinationPath) {
			let sourcePath = NSBundle.mainBundle().pathForResource("default", ofType: "sqlite")!
			_ = try? fileManager.copyItemAtPath(sourcePath, toPath: destinationPath)
		}
		
		self.database = FMDatabase(path: destinationPath)
		self.databaseQueue = FMDatabaseQueue(path: destinationPath)
	}
	
	func openDatabase() -> Bool {
		if self.database == nil {
			self.createDatabaseIfNotExist("default")
		}
		
		if self.database.open() {
			print("Database opened:  \(self.database.databasePath())")
			return true
		} else {
			print("Database failed to open")
			return false
		}
	}
	
	func savePath(path: LFPath) {
		databaseQueue.inDatabase({
			database in
			let insertSQL = "INSERT OR REPLACE INTO tracks (track_geometry) VALUES (LineStringFromText('\(path.WKTString())'));"
			self.database.executeStatements(insertSQL)
		})
	}
	
	func getPathsInRegion(region: MKCoordinateRegion, completion: ([LFPath] -> Void)){
		databaseQueue.inDatabase({
			database in
			let xMin = region.center.longitude - region.span.longitudeDelta
			let yMin = region.center.latitude - region.span.latitudeDelta
			let xMax = region.center.longitude + region.span.longitudeDelta
			let yMax = region.center.latitude + region.span.latitudeDelta
			
			let tolerance = region.span.longitudeDelta / 50
			
			let screenPolygon = "GeomFromText('POLYGON((\(xMin) \(yMin), \(xMin) \(yMax), \(xMax) \(yMax), \(xMax) \(yMin)))')"
			let select = "SELECT track_id, AsBinary(Intersection(Simplify(track_geometry, \(tolerance)), " + screenPolygon + ")) FROM tracks "
			let querySQL = select + "WHERE MbrOverlaps(track_geometry, " + screenPolygon + ") OR MbrContains(track_geometry, " + screenPolygon + ")"
			let results = self.database.executeQuery(querySQL, withArgumentsInArray: nil)!
			
			var paths = [LFPath]()
			
			while (results.next()) {
				if results.hasAnotherRow() {
					if let data = results.dataForColumnIndex(1) {
						let reader = WKBByteReader(data: data)
						reader.byteOrder = Int(CFByteOrderBigEndian.rawValue)
						let geometry = WKBGeometryReader.readGeometryWithReader(reader)
						
						if let lineString = geometry as? WKBLineString {
							let path = LFPath(lineString: lineString)
							paths.append(path)
						} else if let multiLineString = geometry as? WKBMultiLineString {
							print("multiline")
							for lineString in multiLineString.getLineStrings() {
								let path = LFPath(lineString: lineString as! WKBLineString)
								paths.append(path)
							}
						}
					}
				}
			}
			
			completion(paths)
		})
	}
}