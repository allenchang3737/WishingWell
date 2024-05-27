//
//  LUNShareMapViewCell.swift
//  TheWayToBasketball
//
//  Created by Lun Yu Chang on 2024/1/11.
//  Copyright © 2024 LunYuChang. All rights reserved.
//

import UIKit
import MapKit

class LUNShareMapViewCell: UITableViewCell {
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var countryView: LUNCountryView!
    @IBOutlet weak var noteLbl: UILabel!
    
    private var meters: CLLocationDistance = 1000000
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
    }
    
    override func prepareForReuse() {
        if let view = self.imageview.viewWithTag(996) {
            view.removeFromSuperview()
        }
    }
    
    func configure(countryCode: String?,
                   latitude: Double?, longitude: Double?,
                   meters: CLLocationDistance) {
        self.meters = meters
        //Product country
        if let code = countryCode {
            countryView.isHidden = false
            countryView.configure(code: code)
        }else {
            countryView.isHidden = true
        }
        
        //Product Coordinate
        if let latitude = latitude, latitude != 0.0,
           let longitude = longitude, longitude != 0.0 {
            imageview.alpha = 1
            noteLbl.isHidden = true
            let options: MKMapSnapshotter.Options = .init()
            let coordinate = CLLocationCoordinate2D(latitude: latitude,
                                                    longitude: longitude)
            options.region = MKCoordinateRegion(center: coordinate,
                                                latitudinalMeters: self.meters,
                                                longitudinalMeters: self.meters)
            options.size = imageview.frame.size
            options.mapType = .standard
            options.showsBuildings = true
            
            let snapshotter = MKMapSnapshotter(options: options)
            snapshotter.start { snapshot, error in
                if let snapshot = snapshot {
                    //加上地圖針
                    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                    imageView.contentMode = .scaleAspectFit
                    imageView.image = UIImage(named: "location_full_128")
                    
                    var point = snapshot.point(for: coordinate)
                    //Move point to reflect annotation anchor
                    point.x += imageView.bounds.size.width / 2
                    imageView.center = point
                    
                    self.imageview.image = snapshot.image
                    imageView.tag = 996
                    self.imageview.addSubview(imageView)
                    
                }else if let error = error {
                    print("Something went wrong: \(error.localizedDescription)")
                }
            }
       
        }else {
            imageview.alpha = 0.5
            noteLbl.isHidden = false
            noteLbl.text = "Not provided".localized()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
