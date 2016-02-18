import UIKit
import Foundation

class EthernetHostCell: UITableViewCell {
    
    //AppDelegate access
    let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet var hostName : UILabel!
    @IBOutlet var sortField: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }
    
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}



