//
//  LFMapCell.swift
//  LEIFR
//
//  Created by Jinghan Wang on 30/1/17.
//  Copyright © 2017 Echx. All rights reserved.
//

import UIKit

class LFMapCell: LFTableViewCell {

	@IBOutlet var map: MKMapView!
	fileprivate var overlayRenderer: LFGeoPointsOverlayRenderer!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
		
		self.configureMap()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
	fileprivate func configureMap() {
		map.delegate = self
		
		let overlay = LFGeoPointsOverlay()
		map.add(overlay, level: .aboveRoads)
	}
	
}

extension LFMapCell: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if overlay is LFGeoPointsOverlay {
			if self.overlayRenderer == nil {
				self.overlayRenderer = LFGeoPointsOverlayRenderer(overlay: overlay)
			}
			
			return self.overlayRenderer
		} else if overlay is MKCircle {
			let circleRenderer = MKCircleRenderer(overlay: overlay)
			circleRenderer.fillColor = UIColor(red:0.79216, green:0.86274, blue:0.85490, alpha:0.7)
			return circleRenderer
		} else {
			return MKOverlayRenderer(overlay: overlay)
		}
	}
}
