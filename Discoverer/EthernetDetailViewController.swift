import UIKit

class EthernetDetailViewController: UIViewController{
    
    //AppDelegate access
    let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    //back button
    @IBAction func ethernetDetailBackDiscoverer(sender: UIButton) {
        self.performSegueWithIdentifier("detailBackEthernet", sender: self)
    }
    // info labels
    @IBOutlet weak var HostNameLabel: UILabel!
    //IP label hyperlink
    @IBOutlet weak var IPLabel: UIButton!
    @IBAction func IPLabel(IPLabel: UIButton) {
        
        let ethernetDetailWeb:EthernetDeviceWebView = self.storyboard?.instantiateViewControllerWithIdentifier("EthernetDeviceWebView") as! EthernetDeviceWebView
        ethernetDetailWeb.webIP = labelIP
        ethernetDetailWeb.devicePicked = labelHostName
        self.presentViewController(ethernetDetailWeb, animated: true, completion: nil)
    }
    
    @IBOutlet weak var MACLabel: UILabel!
    @IBOutlet weak var LocationLabel: UILabel!
    @IBOutlet weak var ScreenLabel: UILabel!
    @IBOutlet weak var ModelLabel: UILabel!
    @IBOutlet weak var SerialLabel: UILabel!
    @IBOutlet weak var StatusLabel: UILabel!
    @IBOutlet weak var viewContainer: UIView!

    var labelIP = "" as String
    var labelMAC = ""
    var labelSerial = ""
    var labelLocation = ""
    var labelScreen = ""
    var labelModel = ""
    var labelHostName = ""
    //filter status label front & back tag text
    var labelStatus = ""
    var labelStatusPreFiltered = ""
    var labelStatusFiltered = ""
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.Portrait, UIInterfaceOrientationMask.PortraitUpsideDown]
    }
    override func shouldAutorotate() -> Bool {
        return false
    }
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        // Only allow Portrait
        return UIInterfaceOrientation.Portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //load as portrait before locking
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
        
        //left swipe init
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
        
        let deviceSelected = appDel.foundDevicesArray[appDel.foundDeviceIndex]
        labelHostName = deviceSelected.hostName
        labelIP = deviceSelected.IPAddress
        labelMAC = deviceSelected.MACAddress
        labelSerial = deviceSelected.serial
        labelLocation = deviceSelected.location
        labelScreen = deviceSelected.screen
        labelModel = deviceSelected.model
        labelStatus = deviceSelected.status
        
        //set status text color according to string and strip color code
        if labelStatus.rangeOfString("Red") != nil {
            self.StatusLabel.textColor = UIColor.redColor()
            labelStatusPreFiltered = labelStatus.stringByReplacingOccurrencesOfString("[Red]", withString: "")
            labelStatusFiltered = labelStatusPreFiltered.stringByReplacingOccurrencesOfString("[/Red]", withString: "")
        }
        
        if labelStatus.rangeOfString("Green") != nil {
            self.StatusLabel.textColor = UIColor.greenColor()
            labelStatusPreFiltered = labelStatus.stringByReplacingOccurrencesOfString("[Green]", withString: "")
            labelStatusFiltered = labelStatusPreFiltered.stringByReplacingOccurrencesOfString("[/Green]", withString: "")
        }
        
        HostNameLabel.text = labelHostName
        IPLabel.setTitle("\(labelIP)", forState: .Normal)
        MACLabel.text = labelMAC
        SerialLabel.text = labelSerial
        LocationLabel.text = labelLocation
        ScreenLabel.text = labelScreen
        ModelLabel.text = labelModel
        StatusLabel.text = labelStatusFiltered
    }
    
    //left swipe returns to previous page
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == UISwipeGestureRecognizerDirection.Left{
                performSegueWithIdentifier("detailBackEthernet", sender: self)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
