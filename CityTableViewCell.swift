//
//  CityTableViewCell.swift
//  CityRoulette
//
//  Created by Andrea Bigagli on 12/12/15.
//  Copyright © 2015 Andrea Bigagli. All rights reserved.
//

import UIKit

//We need to access our own indexpath when the ratingButton is
//tapped, so lets define a delegate protocol that the tableview controller
//will conform to, we'll notify it about the tap and pass ourselves
//and it will find our indexpath at every tap
protocol CityTableViewCellDelegate: class {
    func favoriteButtonTapped (sender: FavoritedUIButton, cell: CityTableViewCell)
}

class CityTableViewCell: UITableViewCell {

    @IBOutlet weak var favoriteButton: FavoritedUIButton!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBAction func favoriteButtonTapped(sender: FavoritedUIButton) {
        
        sender.isFavorite = !sender.isFavorite
        
        if let tapdelegate = self.delegate {
            //Let the delegate do higher level stuff related to our cell
            //having been favorited
            tapdelegate.favoriteButtonTapped(sender, cell: self)
        }
    }
    
    weak var delegate: CityTableViewCellDelegate?
}
