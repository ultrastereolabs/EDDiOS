import UIKit
import CocoaAsyncSocket

class EthernetViewController: UIViewController, GCDAsyncUdpSocketDelegate {
    
    ///////////////////////Variables///////////////////////
    
    //AppDelegate access
    let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // socket info
    var portNumber: UInt16 = 30303
    var udpSocket: GCDAsyncUdpSocket?
    var netInfo: NetInfo?
    
    //timer elements
    var timer = NSTimer()
    var counter:Float = 0.0 {
        didSet{
            discoverProgress.progress = counter
            if counter >= 1.0{
                timer.invalidate()
                discoverProgress.progress = 0.0
                counter = 0.0
                hostNameList.reloadData()
            } // end if
        } // end counter didset
    } //end counter var
    // found device struct
    struct DiscoveredDevice{
        var hostName:String
        var MACAddress:String
        var serial:String
        var location:String
        var screen:String
        var model:String
        var status:String
        var IPAddress:String
    } // end struct
        
    ///////////////////////Static Objects///////////////////////
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var progressSpacer: UIView!
    @IBOutlet weak var devicesFoundBackground: UINavigationBar!
    
    ///////////////////////Dynamic Objects///////////////////////
    
    @IBOutlet weak var discoverProgress: UIProgressView!
    @IBOutlet weak var devicesFoundLabel: UILabel!
    @IBOutlet weak var hostNameList: UITableView!
    @IBAction func licensesButton(sender: UIButton) {
         self.performSegueWithIdentifier("licenseSegue", sender: self)
    }
    
    ///////////////////////View Functions///////////////////////
    
    func timerFire() {
        counter = counter + 0.01
            }
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
        
        //start view in portrait
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
        
        //start progress at 0
        discoverProgress.progress = 0.0
        
        //setup socket
        self.udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        setupUDPSocket(30303)

    }
    
    override func viewWillDisappear(animated: Bool) {
        // close socket when leaving the view
        udpSocket!.close()
    }
    
    @IBAction func discoverButton(sender: UIButton!) {
        
        
        if discoverProgress.progress == 0 {
            // sends discover message if button has not been pressed yet
            timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "timerFire", userInfo: nil, repeats: true)
            if appDel.buttonPressedCount < 1 {
                //triggers udpSocket()
                discoverDevices()
                hostNameList.reloadData()
            }else{
                //empty the array and start over
                appDel.foundDevicesArray = []
                //triggers udpSocket()
                discoverDevices()
                hostNameList.reloadData()
            }
        }else{}
        
        //increments button count to prevent reloading of dupe data
        appDel.buttonPressedCount = appDel.buttonPressedCount + 1

    }// end discover button
    
    // called when a UDP message gets received
    func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        
        if let mssg = String(data: data, encoding: NSASCIIStringEncoding) {
            // take glob data and split into array of individual items
            var mssgItemArray:[String] = ["","","","","","","",""]
            // use enumerate to give each component an index
            for (index, mssgComponent) in mssg.componentsSeparatedByString("\r\n").enumerate(){
                mssgItemArray[index] = "\(mssgComponent)"
                } // end item loop
            // append the IP given from address parser function
            mssgItemArray[7] = getIPfromAddress(address)
            
            // make class instance and plug in values
            let deviceFound = DiscoveredDevice(
                    hostName: "\(mssgItemArray[0])",
                    MACAddress: "\(mssgItemArray[1])",
                    serial: "\(mssgItemArray[2])",
                    location: "\(mssgItemArray[3])",
                    screen: "\(mssgItemArray[4])",
                    model: "\(mssgItemArray[5])",
                    status: "\(mssgItemArray[6])",
                    IPAddress: "\(mssgItemArray[7])")
            
            // filter errant results
        if deviceFound.MACAddress != "" {
            appDel.foundDevicesArray.append(deviceFound)
            } // end if
            
            
            } // end mssg string process
        else {
            print("UNKNOWN MSSG: \(data)")
            dispatch_async(dispatch_get_main_queue()) {
                self.alert("Received unknown message.")
                } // end mssg error
            } // end new data income operation
        
    } // end udpsocket func
    
    ///////////////////////Table Functions///////////////////////
    
    func numberOfSectionsInTableView(HostList: UITableView) -> Int {
        return 1
    }
    
    func tableView(hostNameList: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDel.foundDevicesArray.count
    }
    
    func tableView(hostNameList: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = hostNameList.dequeueReusableCellWithIdentifier("EthernetHostCell", forIndexPath: indexPath) as! EthernetHostCell
        
        cell.hostName.text = appDel.foundDevicesArray[indexPath.row].hostName
        
        return cell
    }
    
    func tableView(hostNameList: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        let ethernetDetailVC:EthernetDetailViewController = self.storyboard?.instantiateViewControllerWithIdentifier("EthernetDetailViewController") as! EthernetDetailViewController
        
        let deviceSelected = appDel.foundDevicesArray[indexPath.row]
        ethernetDetailVC.labelHostName = deviceSelected.hostName
        ethernetDetailVC.labelIP = deviceSelected.IPAddress
        ethernetDetailVC.labelMAC = deviceSelected.MACAddress
        ethernetDetailVC.labelSerial = deviceSelected.serial
        ethernetDetailVC.labelLocation = deviceSelected.location
        ethernetDetailVC.labelScreen = deviceSelected.screen
        ethernetDetailVC.labelModel = deviceSelected.model
        ethernetDetailVC.labelStatus = deviceSelected.status
        
        //set appDel index path for getting IP into web view
        appDel.foundDeviceIndex = indexPath.row
        
        self.presentViewController(ethernetDetailVC, animated: true, completion: nil)
    
    } // end didselectrow
    
    ///////////////////////Subroutines///////////////////////
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    // set netinfo struct
    func getMyWifiAddress() {
        if let netinfo = NetworkUtilities.sharedInstance.getMyWiFiAddress() {
            self.netInfo = netinfo
        } else {
            self.alert("This device's address not available.")
        }
    }
    
    // setup/bind socket
    func setupUDPSocket(port: UInt16) {
        guard let udpSocket = self.udpSocket else {
            self.alert("No udp socket.")
            return
        }
        try! udpSocket.bindToPort(portNumber)
        try! udpSocket.enableBroadcast(true)
        try! udpSocket.beginReceiving()
    }
    
    // alert
    func alert(text: String) {
        let alert = UIAlertController(title: text, message: nil, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    // send UDP msg
    func discoverDevices() {
        
        self.getMyWifiAddress()
        guard let netInfo = self.netInfo, udpSocket = self.udpSocket else {
            self.alert("Netinfo or udpSocket not available.")
            return
        }
        let broadcast = netInfo.broadcast
        let message = "Discovery: Who is out there?".dataUsingEncoding(NSASCIIStringEncoding)
        dispatch_async(dispatch_get_main_queue()){
            // self.alert("Discovery Message Sent.")
        }
        udpSocket.sendData(message, toHost: broadcast, port: portNumber, withTimeout: 2, tag: 1)
    }
    
    override func didReceiveMemoryWarning() {
        didReceiveMemoryWarning()
    }
    
    // takes nsdata ip address and returns readable string
    func getIPfromAddress(address:NSData!) -> String{
        
        // split IP address into array of characters
        // the number of elements
        let count = address.length / sizeof(UInt8)
        // create array of appropriate length
        var wholeAddressCharactersArray = [UInt8](count: count, repeatedValue: 0)
        // copy bytes into array
        address.getBytes(&wholeAddressCharactersArray, length:count * sizeof(UInt8))
        // empty string
        var ipAddress = ""
        // make an IP string from the address array
        ipAddress += "\(wholeAddressCharactersArray[4])"
        ipAddress += "."
        ipAddress += "\(wholeAddressCharactersArray[5])"
        ipAddress += "."
        ipAddress += "\(wholeAddressCharactersArray[6])"
        ipAddress += "."
        ipAddress += "\(wholeAddressCharactersArray[7])"
        
        return ipAddress
    }
    
    //////////////////////////////////////////////
    
    
} // end viewcontroller

