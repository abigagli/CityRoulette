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
    func ratingButtonTappedOnCell (cell: CityTableViewCell)
}

class CityTableViewCell: UITableViewCell {

    @IBOutlet weak var ratingButton: UIButton!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBAction func ratingTapped(sender: UIButton) {
        
        let favoriteButton = sender as! FavoritedUIButton
        
        favoriteButton.isFavorite = !favoriteButton.isFavorite
        
        if let tapdelegate = self.delegate {
            //Let the delegate do higher level stuff related to our cell
            //having been tapped
            tapdelegate.ratingButtonTappedOnCell (self)
        }
    }
    
    weak var delegate: CityTableViewCellDelegate?
}
