import UIKit

class EthernetDeviceWebView: UIViewController {

    @IBOutlet weak var deviceWebView: UIWebView!
    @IBOutlet weak var webBackEthernetDetail: UIButton!
    // @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var navigationSpacer: UIView!
    @IBOutlet weak var ethernetDetailWebHeader: UILabel!
    @IBOutlet weak var topSpacer: UIView!
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    //passed from prior view
    var webIP = ""
    var devicePicked = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //header
        ethernetDetailWebHeader.text = "\(devicePicked)\r\n\(webIP)"
        
        //web view
        let deviceURL = NSURL(string: "http://\(webIP)") //
        let deviceURLRequest = NSURLRequest(URL: deviceURL!)
        deviceWebView.loadRequest(deviceURLRequest)
        
        //left swipe
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture")
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
    }
    
    //left swipe returns to previous page
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == UISwipeGestureRecognizerDirection.Left{
                performSegueWithIdentifier("webBackDetail", sender: self)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        didReceiveMemoryWarning()
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    

}
