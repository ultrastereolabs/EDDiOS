import UIKit
import CocoaAsyncSocket
import CoreFoundation
import Darwin
import Foundation

class EthernetViewController: UIViewController, GCDAsyncUdpSocketDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate {
    
    //AppDelegate access
    let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    //plist access
    let sortPickerArray = NSArray(contentsOfFile: NSBundle.mainBundle().pathForResource("pickerArrayItems", ofType: "plist")!)
    
    ///////////////////////Static Objects///////////////////////
    // MARK: - Static Objects
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var progressSpacer: UIView!
    @IBOutlet weak var devicesFoundBackground: UINavigationBar!
    @IBOutlet weak var sortLabel: UILabel!
    @IBOutlet weak var devicesFoundLabel: UILabel!
    
    ///////////////////////Dynamic Objects///////////////////////
    // MARK: - Dynamic Objects
    
    @IBOutlet var discoverProgress: UIProgressView!
    @IBOutlet weak var hostNameList: UITableView!
    
    ///////////////////////Actions///////////////////////
    // MARK: - Actions
    
    @IBAction func discoverButton(sender: UIButton!) {
        
        // outer if block is a simple debouncer
        if discoverProgress.progress == 0 {
            
            // instantiate a timer, calls counter's didSet
            timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "timerFire", userInfo: nil, repeats: true)
            
            appDel.foundDevicesArray = []
            // clear any previous sorting arrays
            appDel.sortFieldHostNameArray = []
            appDel.sortFieldIPAddressArray = []
            appDel.sortFieldMACAddressArray = []
            appDel.sortFieldLocationArray = []
            appDel.sortFieldScreenArray = []
            appDel.sortFieldModelArray = []
            appDel.sortFieldSerialArray = []
            appDel.sortFieldStatusArray = []
            
            // note: discoverDevices triggers udpSocket()
            discoverDevices()
            hostNameList.reloadData()
            
            // reset state check
            didGetUDPM = false
        }
        
        //increments button count to prevent reloading of dupe data
        appDel.buttonPressedCount = appDel.buttonPressedCount + 1

    } // end discover button
    
    @IBAction func licensesButton(sender: UIButton) {
         self.performSegueWithIdentifier("licenseSegue", sender: self)
    }
    
    ///////////////////////Events///////////////////////
    // MARK: - Events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //start view in portrait
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
        
        //start progress at 0
        discoverProgress.progress = 0.0
        
        //setup socket
        self.udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        setupUDPSocket(30303)
        
        self.pickerTextField.inputView = picker
        
        picker.dataSource = self
        picker.delegate = self
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        // close socket when leaving the view
        udpSocket!.close()
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        didReceiveMemoryWarning()
    }
    
    ///////////////////////Host Name Table///////////////////////
    // MARK: - Host Name table
    
    func numberOfSectionsInTableView(hostNameList: UITableView) -> Int {
        return 1
    }
    
    func tableView(hostNameList: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDel.foundDevicesArray.count
    }
    
    func tableView(hostNameList: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = hostNameList.dequeueReusableCellWithIdentifier("EthernetHostCell", forIndexPath: indexPath) as! EthernetHostCell
        
        cell.hostName.text = appDel.foundDevicesArray[indexPath.row].hostName
        
        //load sort field from array whose contents are based on mode selected
        if appDel.sortFieldTextDelegate != [] {
            cell.sortField.text = appDel.sortFieldTextDelegate[indexPath.row]
        }else{
            cell.sortField.text = ""
        }

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
    
    ///////////////////////Timer///////////////////////
    // MARK: - Timer
    
    var timer = NSTimer()
    var counter:Float = 0.0 {
        didSet{
            discoverProgress.progress = counter
            // when done...
            if counter >= 1.0{
                // print alert if nothing found
                if didGetUDPM == false {
                    self.alert("No devices found 😕")
                }
                // kill timer
                timer.invalidate()
                // set picker when timer reaches full
                switch self.pickerTextField.text {
                    case "Host Name"?:
                        pickerView(picker, didSelectRow: 0, inComponent: 1)
                    case "Location"?:
                        pickerView(picker, didSelectRow: 1, inComponent: 1)
                    case "Screen"?:
                        pickerView(picker, didSelectRow: 2, inComponent: 1)
                    case "IP Address"?:
                        pickerView(picker, didSelectRow: 3, inComponent: 1)
                    case "MAC Address"?:
                        pickerView(picker, didSelectRow: 4, inComponent: 1)
                    case "Model"?:
                        pickerView(picker, didSelectRow: 5, inComponent: 1)
                    case "Serial"?:
                        pickerView(picker, didSelectRow: 6, inComponent: 1)
                    case "Status"?:
                        pickerView(picker, didSelectRow: 7, inComponent: 1)
                    default:
                        break
                }
                // reset discover bar
                discoverProgress.progress = 0.0
                // reset counter
                counter = 0.0
                // reload table
                hostNameList.reloadData()
                hostNameList.reloadInputViews()
            } // end if counter done
        } // end counter didset
    } //end counter
    
    func timerFire() {
        counter = counter + 0.01
    }
    
    ///////////////////////Sort Mode Pickerview///////////////////////
    // MARK: - Pickerview
    
    //text field outlet
    @IBOutlet weak var pickerTextField: UITextField!
    //picker source
    var picker: UIPickerView = UIPickerView()
    var pickerTextDelegate:String?
    
    //string attribute for later fancification
    // let pickerStringAttribute = [ NSFontAttributeName: UIFont(name: "AvenirNext-UltraLight", size: 18.0)! ]
    
    func pickerView(picker: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.sortPickerArray!.count
    }
    
    func numberOfComponentsInPickerView(picker: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(picker: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sortPickerArray![row] as? String
    }
    
    @IBAction func closeSortPicker(sender: UIButton) {
        self.pickerTextField.resignFirstResponder()
    }
    
    // called when picker item is chosen
    func pickerView(picker: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        //set text field to items in picker
        self.pickerTextField.text = self.sortPickerArray![row] as? String
        pickerTextDelegate = self.pickerTextField.text
        self.pickerTextField.resignFirstResponder()
        
        // sort foundDevicesArray to arrange cells by selected sort mode; set sort field to point to the array based on sort mode text
        switch self.pickerTextField.text {
            case "Host Name"?:
                appDel.foundDevicesArray.sortInPlace({$0.hostName.localizedCaseInsensitiveCompare($1.hostName) == NSComparisonResult.OrderedAscending})
                appDel.sortFieldTextDelegate = []
            case "Location"?:
                appDel.foundDevicesArray.sortInPlace({$0.location.localizedCaseInsensitiveCompare($1.location) == NSComparisonResult.OrderedAscending})
                appDel.sortFieldTextDelegate = appDel.sortFieldLocationArray
            case "Screen"?:
                appDel.foundDevicesArray.sortInPlace({$0.screen.localizedCaseInsensitiveCompare($1.screen) == NSComparisonResult.OrderedAscending})
                appDel.sortFieldTextDelegate = appDel.sortFieldScreenArray
            case "IP Address"?:
                appDel.foundDevicesArray.sortInPlace({$0.IPAddress.localizedCaseInsensitiveCompare($1.IPAddress) == NSComparisonResult.OrderedAscending})
                appDel.sortFieldTextDelegate = appDel.sortFieldIPAddressArray
            case "MAC Address"?:
                appDel.foundDevicesArray.sortInPlace({$0.MACAddress.localizedCaseInsensitiveCompare($1.MACAddress) == NSComparisonResult.OrderedAscending})
                appDel.sortFieldTextDelegate = appDel.sortFieldMACAddressArray
            case "Model"?:
                appDel.foundDevicesArray.sortInPlace({$0.model.localizedCaseInsensitiveCompare($1.model) == NSComparisonResult.OrderedAscending})
                appDel.sortFieldTextDelegate = appDel.sortFieldModelArray
            case "Serial"?:
                appDel.foundDevicesArray.sortInPlace({$0.serial.localizedCaseInsensitiveCompare($1.serial) == NSComparisonResult.OrderedAscending})
                appDel.sortFieldTextDelegate = appDel.sortFieldSerialArray
            case "Status"?:
                appDel.foundDevicesArray.sortInPlace({$0.status.localizedCaseInsensitiveCompare($1.status) == NSComparisonResult.OrderedAscending})
                appDel.sortFieldTextDelegate = appDel.sortFieldStatusArray
            default:
                break
            }
        
        // sort the delegate 'sort field' text
        appDel.sortFieldTextDelegate.sortInPlace({$0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})
        
        hostNameList.reloadData()

    }
    
    ///////////////////////Data///////////////////////
    // MARK: - Data
    
    // user settings for future implementation
    // let defaults = NSUserDefaults.standardUserDefaults()
    
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
    
    ///////////////////////Socket///////////////////////
    // MARK: - Socket
    
    // socket info
    var portNumber: UInt16 = 30303
    var udpSocket: GCDAsyncUdpSocket?
    var netInfo: NetInfo?
    
    // UDP received state check
    var didGetUDPM:Bool = false
    
    // called when a UDP message gets received
    func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        
        if let mssg = String(data: data, encoding: NSASCIIStringEncoding) {
            // take glob data and split into array of individual items
            var mssgItemArray:[String] = ["","","","","","","",""]
            // index the message via components separated by character return line feed
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
            
            // filter errant results, prepare for sorting
            if deviceFound.MACAddress != "" {
                
                appDel.foundDevicesArray.append(deviceFound)
                // appDel.sortFieldHostNameArray.append(deviceFound.hostName)
                appDel.sortFieldIPAddressArray.append(deviceFound.IPAddress)
                appDel.sortFieldMACAddressArray.append(deviceFound.MACAddress)
                appDel.sortFieldLocationArray.append(deviceFound.location)
                appDel.sortFieldScreenArray.append(deviceFound.screen)
                appDel.sortFieldModelArray.append(deviceFound.model)
                appDel.sortFieldSerialArray.append(deviceFound.serial)
                appDel.sortFieldStatusArray.append(deviceFound.status)
                
                // resort arrays every time a new element is added
                switch self.pickerTextField.text {
                    case "Host Name"?:
                        appDel.foundDevicesArray.sortInPlace({$0.hostName.localizedCaseInsensitiveCompare($1.hostName) == NSComparisonResult.OrderedAscending})
                        appDel.sortFieldHostNameArray.sortInPlace({$0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})
                    case "Location"?:
                        appDel.foundDevicesArray.sortInPlace({$0.location.localizedCaseInsensitiveCompare($1.location) == NSComparisonResult.OrderedAscending})
                        appDel.sortFieldIPAddressArray.sortInPlace({$0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})
                    case "Screen"?:
                        appDel.foundDevicesArray.sortInPlace({$0.screen.localizedCaseInsensitiveCompare($1.screen) == NSComparisonResult.OrderedAscending})
                        appDel.sortFieldMACAddressArray.sortInPlace({$0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})
                    case "IP Address"?:
                        appDel.foundDevicesArray.sortInPlace({$0.IPAddress.localizedCaseInsensitiveCompare($1.IPAddress) == NSComparisonResult.OrderedAscending})
                        appDel.sortFieldLocationArray.sortInPlace({$0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})
                    case "MAC Address"?:
                        appDel.foundDevicesArray.sortInPlace({$0.MACAddress.localizedCaseInsensitiveCompare($1.MACAddress) == NSComparisonResult.OrderedAscending})
                        appDel.sortFieldScreenArray.sortInPlace({$0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})
                    case "Model"?:
                        appDel.foundDevicesArray.sortInPlace({$0.model.localizedCaseInsensitiveCompare($1.model) == NSComparisonResult.OrderedAscending})
                        appDel.sortFieldModelArray.sortInPlace({$0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})
                    case "Serial"?:
                        appDel.foundDevicesArray.sortInPlace({$0.serial.localizedCaseInsensitiveCompare($1.serial) == NSComparisonResult.OrderedAscending})
                        appDel.sortFieldSerialArray.sortInPlace({$0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})
                    case "Status"?:
                        appDel.foundDevicesArray.sortInPlace({$0.status.localizedCaseInsensitiveCompare($1.status) == NSComparisonResult.OrderedAscending})
                        appDel.sortFieldStatusArray.sortInPlace({$0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})
                    default:
                        break
                }
                
            } // end errant result handling
            
            //ping didgetUDP
            didGetUDPM = true
            print("got udp")
            
        } // end new UDP message received
        
        // error handle
        else {
            print("UNKNOWN MSSG: \(data)")
            dispatch_async(dispatch_get_main_queue()) {
                self.alert("Received unknown message.")
            } // end mssg error
        } // end new data income operation
        
    } // end udpsocket func
    
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

    ///////////////////////Orientation///////////////////////
    // MARK: - Orientation
    
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
    
} // end viewcontroller

