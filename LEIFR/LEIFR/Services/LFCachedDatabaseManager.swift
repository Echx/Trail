//
//  LFCachedDatabaseManager.swift
//  LEIFR
//
//  Created by Lei Mingyu on 29/10/16.
//  Copyright © 2016 Echx. All rights reserved.
//

import RealmSwift
import MapKit

class LFCachedDatabaseManager: NSObject {
    static let shared = LFCachedDatabaseManager()
    
    fileprivate let cacheRealm = try! Realm()
    fileprivate let bufferSize = 2000
    
    func savePoints(coordinates: [CLLocationCoordinate2D], zoomLevel: Int) {
        let cacheRealm = try! Realm()
        let currentLevels = cacheRealm.objects(LFCachedLevel.self).filter("level = \(zoomLevel)")
        var currentLevel = LFCachedLevel()
        
        if currentLevels.count > 0 {
            currentLevel = currentLevels.first!
        } else {
            try! cacheRealm.write {
                currentLevel.level = zoomLevel
                cacheRealm.add(currentLevel)
            }
        }
        
        var size = coordinates.count
        var current = 0
        while size > 0 {
            var count = 0
            size -= bufferSize
            cacheRealm.beginWrite()
            while current < coordinates.count - 1 && count < bufferSize - 1 {
                current += 1
                count += 1
                let mapPoint = MKMapPointForCoordinate(coordinates[current])
                let x = Int(mapPoint.x)
                let y = Int(mapPoint.y)
                
                let cachedPoints = currentLevel.points.filter("x = \(x) AND y = \(y)")
                if cachedPoints.count > 0 {
                    let cachedPoint = cachedPoints.first!
                    cachedPoint.count += 1
                } else {
                    let newPoint = LFCachedPoint()
                    newPoint.count = 1
                    newPoint.x = x
                    newPoint.y = y
                    currentLevel.points.append(newPoint)
                }
            }
            try! cacheRealm.commitWrite()
        }
    }
    
    func getPointsInRect(_ rect: MKMapRect, zoomScale: MKZoomScale) -> [MKMapPoint] {
        let zoomLevel = zoomScale.toZoomLevel()
		let cacheRealm = try! Realm()
        let levelPredicate = "level = \(zoomLevel)"
        
        let minX = Int(rect.origin.x - rect.size.width)
        let maxX = Int(rect.origin.x + rect.size.width)
        let minY = Int(rect.origin.y - rect.size.height)
        let maxY = Int(rect.origin.y + rect.size.height)
        let xPredicate = "x >= \(minX) AND x <= \(maxX)"
        let yPredicate = "y >= \(minY) AND y <= \(maxY)"
        let currentLevels = cacheRealm.objects(LFCachedLevel.self).filter(levelPredicate)
        
        guard currentLevels.count > 0 else {
            return [MKMapPoint]()
        }
        
        let points = currentLevels[0].points.filter("\(xPredicate) AND \(yPredicate)")
        return points.map{MKMapPoint(x: Double($0.x), y: Double($0.y))}
    }
    
    func synchronizeDatabase() {
        print("synchronizing database")
    }
    
    func reconstructDatabase() {
//        clearDatabase()
        
        for level in 1...21 {
            print("reconstructing database at level \(level)")
            
            let gridSize = self.gridSize(for: level)
            
            LFDatabaseManager.shared.getPointsInRegion(MKCoordinateRegionForMapRect(MKMapRectWorld), gridSize: gridSize, completion: {
                coordinates in
                
                self.savePoints(coordinates: coordinates, zoomLevel: level)
            })
        }
		
		print("database reconstruction completed")
    }
    
    func clearDatabase() {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    func destroyDatabase() {
        let databaseDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let array = try! FileManager.default.contentsOfDirectory(atPath: databaseDirectory)
        
        for name in array {
            if name != "default.sqlite" {
                try! FileManager.default.removeItem(atPath: "\(databaseDirectory)/\(name)")
            }
        }
    }
    
    fileprivate func gridSize(for zoomLevel: Int) -> Double {
        return 1 / pow(2.0, Double(zoomLevel)) * MKMapSizeWorld.width / 5120000
    }
}
