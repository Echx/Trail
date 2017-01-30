//
//  LFImageCell.swift
//  LEIFR
//
//  Created by Jinghan Wang on 30/1/17.
//  Copyright © 2017 Echx. All rights reserved.
//

import UIKit

class LFImageCell: LFTableViewCell {
	
	@IBOutlet var mainImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
		

		let layer = self.mainImageView.layer
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOffset = CGSize(width: 0, height: 0)
		layer.shadowOpacity = 0.15
		layer.shadowRadius = 3
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
