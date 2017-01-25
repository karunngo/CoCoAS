//
//  ViewController.swift
//  CoCoAS
//
//  Created by orihara ayami on 2016/12/31.
//  Copyright © 2016年 orihara ayami. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController:UIViewController,MSBClientManagerDelegate,MSBClientTileDelegate,CLLocationManagerDelegate{
    var client:MSBClient? = nil
    
    //Tileのレイアウト
    let TILEID:NSUUID = NSUUID.init(UUIDString: "CABDBA9F-12FD-47A5-8453-E7270A43BB98")!
    let YESNum:UInt16 = 11
    let NoNum:UInt16 = 12
    
    //通知判定
    var doNotification:Bool = false;

    //生体データ
    var hr:Int = 0
    var gsr:Int = 0
    var accX:Double = 0.0
    var accY:Double = 0.0
    var accZ:Double = 0.0
    var accS:Double = 0.0
    
    //位置データ取得
    var clmanager: CLLocationManager!
    var latitude: CLLocationDegrees!
    var longitude: CLLocationDegrees!
    
    //View
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var HRtext: UILabel!
    @IBOutlet weak var GSRtext: UILabel!
    @IBOutlet weak var accXtext: UILabel!
    @IBOutlet weak var accYtext: UILabel!
    @IBOutlet weak var accZtext: UILabel!
    @IBOutlet weak var latitudeText: UILabel!
    @IBOutlet weak var longitudeText: UILabel!
    
    
    
    //MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.message.text="CoCoASにようこそ!"
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        //データ保存用のファイルパス
        
        
        //位置情報の取得開始
        clmanager = CLLocationManager()
        longitude = CLLocationDegrees()
        latitude = CLLocationDegrees()
        clmanager.delegate = self
        clmanager.requestAlwaysAuthorization()
        clmanager.startUpdatingLocation()
        
        //MSBandに接続　→　接続後はMSBClientManagerDelegateが作動
        MSBClientManager.sharedManager().delegate=self
        let clients:NSArray = MSBClientManager.sharedManager().attachedClients()
        if clients.firstObject == nil{
            self.message.text="Clientsが空だよ！"
            return
        }
        self.client = clients.firstObject as? MSBClient
        if self.client == nil{
            self.message.text="Failed! No Bands attached."
        }
        MSBClientManager.sharedManager().connectClient(self.client)
        self.message.text="Please wait. Connecting to Band "
        
        //終了したら、clientとの接続を切る
        notificationCenter.addObserver(
            self,
            selector: "closeClients:",
            name:UIApplicationWillTerminateNotification,
            object: nil)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //TODO:5秒ごとに保存
    func saveTimer(timer:NSTimer){
        //現在時刻取得(CSVにするにあたり、String化)
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let now = NSDate()
        let nowString = dateFormatter.stringFromDate(now)
        
        //データの保存→平均にする？(今は一旦置いとこう)
        
        //初期化
        
        
    }
    //TODO:10分ごとに送信
    
    //MARK: -
    
    //MARK:MSBClientManagerDelegate(MSBandとの接続管理)
    func clientManager(clientManager: MSBClientManager!, clientDidConnect client: MSBClient!) {
        startCoCoAS(clientManager, client: client)
    }
    
    func clientManager(clientManager: MSBClientManager!, clientDidDisconnect client: MSBClient!) {
        //再接続
        print("Client切れたよ！")
        //MSBClientManager.sharedManager().connectClient(self.client)
    }
    
    func clientManager(clientManager: MSBClientManager!, client: MSBClient!, didFailToConnectWithError error: NSError!) {
        //再接続
        print("Client接続失敗してるよ")
        startCoCoAS(clientManager, client: client)
    }

    func startCoCoAS(clientManager: MSBClientManager,client:MSBClient){
        print("client did connected!!")
        self.client!.tileDelegate = self
        //Pageをtileに送る
        var tile:MSBTile = self.tileWithButtonLayout()!
        self.client?.tileManager.addTile(tile, completionHandler: {
            (err) in
            if (err == nil || err.code == MSBErrorType.TileAlreadyExist.rawValue){
                self.message.text = "Creating a page with text button..."
                var pageDatas = self.buttonPage()
                self.client?.tileManager.setPages(pageDatas, tileId: self.TILEID, completionHandler: {
                    (err2) in
                    if (err2 == nil) {
                        self.message.text = "Page sent!"
                    }else{
                        self.message.text = err2.description
                        print("error2:" + err2.description)
                    }
                })
            }else{
                self.message.text = err.description
                print("error1:" + err.description)
            }
        })
        
        //生体データ取得開始
        if self.client?.sensorManager.heartRateUserConsent() == MSBUserConsent.Granted{
            startHeartRateUpdates(self.client!)
        }else{
            self.message.text = "Requesting user consent for accessing HeartRate..."
            self.client?.sensorManager.requestHRUserConsentWithCompletion(
                {[weak self](userConsent:Bool,err:NSError!) -> Void in
                    if let weakSelf = self {
                        if(userConsent){
                            /*
                             let startHRselector:Selector = #selector(ViewController.startHeartRateUpdates)
                             NSTimer.scheduledTimerWithTimeInterval(5,target: weakSelf,selector:　startHRselector,userInfo: weakSelf.client!,repeats: true)
                             */
                            weakSelf.startHeartRateUpdates(weakSelf.client!)
                        }else{
                            weakSelf.HRtext.text = "User consent declined";
                        }
                    }
                })
        }
        
        self.startGSRUpdates()
        self.startAccelermaterUpdates()
        
        //通知の開始
        self.doNotification = true;
        self.sendNotificationToBand(self.client!)
        
    }
    

    //MARK: -
    //MARK:MSBandTileの初期化
    //MSBandのタイルのレイアウトを定義
    func tileWithButtonLayout()->MSBTile?{
        let tileName:String = "CoCoAS tile"
        var tile:MSBTile? = nil
        //create tile icon
        do{
        let tileIcon:MSBIcon = try MSBIcon.init(UIImage: UIImage.init(named: "Stress.png")!)
        let smallIcon:MSBIcon = try MSBIcon.init(UIImage: UIImage.init(named: "StressS.png")!)
        tile = try MSBTile.init(id: TILEID, name: tileName, tileIcon: tileIcon, smallIcon: smallIcon)
        }catch{
        }
        
        //テキストボックス
        let textBlock = MSBPageTextBlock.init(rect: MSBPageRect.init(x: 0, y: 0, width: 200, height: 400), font: MSBPageTextBlockFont.Small)
        textBlock.elementId = 10
        textBlock.baseline = 25
        textBlock.baselineAlignment = MSBPageTextBlockBaselineAlignment.Relative
        textBlock.horizontalAlignment = MSBPageHorizontalAlignment.Center
        textBlock.autoWidth = false
        textBlock.margins = MSBPageMargins.init(left: 5, top: 2, right: 5, bottom: 2)
        
        //テキストボタン
        let buttonYes = MSBPageTextButton.init(rect: MSBPageRect.init(x: 0, y: 0, width: 100, height: 40))
        buttonYes.elementId = self.YESNum
        buttonYes.horizontalAlignment = MSBPageHorizontalAlignment.Center
        buttonYes.margins = MSBPageMargins.init(left: 5, top: 2, right: 5, bottom: 2)
        
        let buttonNo = MSBPageTextButton.init(rect: MSBPageRect.init(x: 0, y: 0, width: 100, height: 40))
        buttonNo.elementId = self.NoNum
        buttonNo.horizontalAlignment = MSBPageHorizontalAlignment.Center
        buttonNo.margins = MSBPageMargins.init(left: 5, top: 2, right: 5, bottom: 2)
        
        do{
        try buttonYes.pressedColor = MSBColor.init(UIColor:UIColor.redColor())
        try buttonNo.pressedColor = MSBColor.init(UIColor:UIColor.cyanColor())
        }catch{
        print("buttonの色かわらず！")}
        
        //配置
        let flowPanelText = MSBPageFlowPanel.init(rect: MSBPageRect.init(x: 15, y: 0, width: 230, height: 50))
        let flowPanelButton = MSBPageFlowPanel.init(rect: MSBPageRect.init(x: 15, y: 0, width: 230, height: 50))
        flowPanelText.addElement(textBlock)
        flowPanelButton.addElement(buttonYes)
        flowPanelButton.addElement(buttonNo)
        flowPanelButton.orientation = MSBPageFlowPanelOrientation.Horizontal
        
        let flowPanel = MSBPageFlowPanel.init(rect: MSBPageRect.init(x: 15, y: 0, width: 230, height: 105))
        flowPanel.addElement(flowPanelText)
        flowPanel.addElement(flowPanelButton)
        
        let pageLayout = MSBPageLayout.init(root: flowPanel)
        tile?.pageLayouts.addObject(pageLayout)
        return tile
    }

    //レイアウトの中身も入ったPageLayoutを返す
    func buttonPage()->[AnyObject]{
        let pageID:NSUUID = NSUUID.init(UUIDString:  "1234BA9F-12FD-47A5-83A9-E7270A43BB99")!
        var pageValue:[AnyObject]? = nil
        do{
            pageValue = [try MSBPageTextButtonData.init(elementId: 11, text: "Yes!"),
                         try MSBPageTextButtonData.init(elementId: 12,text:"No"),
                         try MSBPageTextBlockData.init(elementId: 10, text: "Are You Stressed?")]
        }catch{
        }
        let pageData = MSBPageData.init(id: pageID, layoutIndex: 0, value: pageValue)
        let pageDatas:[AnyObject] = [pageData!]
        return pageDatas
    }

    
    
    //MARK: -
    //MARK:MSBandへの通知を管理
    func sendNotificationToBand(client:MSBClient){
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0)) {
            while(true){
                if self.doNotification{
                    let now = NSDate()
                    //TODO: 直前の通知＋30分後を調べる。今の時刻がそれよりあとなら、通知をする
                    let startNotifiDate = NSDate(timeInterval: 60*30, sinceDate:now)//nowを直前通知時刻にすること。
                    print("通知開始予定時刻：")
                    if self.judgeStress() && now.compare(startNotifiDate) == .OrderedAscending {
                        print("judgeStressがスタート")
                        let tileString = "Are You Stressed?"
                        let bodyString = "Please labeled." //+ 現在時刻
                        client.notificationManager.showDialogWithTileID(self.TILEID, title: tileString, body: bodyString, completionHandler:{
                            (sendError) in
                            if(sendError == nil){
                                print("送るのは成功")
                                self.doNotification = false
                                print("falseになったよ")
                            }else{
                                print(sendError.description)
                            }
                        })
                        self.doNotification = false;
                    }
                    sleep(500)
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                // 上でさせた作業でUI機能が呼ばれた時
            }
        }

    }
    
    //ストレスがあるかの判定
    func judgeStress() -> Bool{
    var isStress:Bool = false
        if self.hr > 65{
            isStress = true
        }
        return isStress
    }
    //MARK: -
    //MARK:MSBand(のTile)からの通知を管理
    func client(client: MSBClient!, tileDidOpen event: MSBTileEvent!) {
    }
    
    func client(client: MSBClient!, tileDidClose event: MSBTileEvent!) {
    }
    
    func client(client: MSBClient!, buttonDidPress event: MSBTileButtonEvent!) {
        print("pressed button!")
        //Bandへ通知
        let tileString = "Thank you!"
        let bodyString = "You labeled.Please go back." //FIX ME: 現在時刻を加える？
        client.notificationManager.showDialogWithTileID(TILEID, title: tileString, body: bodyString, completionHandler: {
            (didPressError) in
            if didPressError != nil{
                print (didPressError.description)
            }
        })
        //TODO:ラベルを取得し永続化
        let nowButton:String = event.buttonId.description
        print(nowButton)
        
        let now = NSDate()
        
        
        self.doNotification = true;
    }
    
    

    //MARK:-
    //MARK: Helper methods
    //画面が閉じた時の処理
    func closeClients(){
        stopHeartRateUpdates()
        stopGSRUpdates()
        stopAccelermaterUpdates()
        MSBClientManager.sharedManager().cancelClientConnection(self.client)
        print("接続を切ったよ！")
        
    }
    //HRQualityをStringで返す
    func qualityToString(hrData:MSBSensorHeartRateData!)->String{
        switch hrData.quality {
        case MSBSensorHeartRateQuality.Acquiring:
            return "Acquiring"
        case MSBSensorHeartRateQuality.Locked:
            return "Locked"
        }
    }
    
    
    
    
    
    //MARK: -
    //MARK:ライフログデータ取得
    //HR
    func startHeartRateUpdates(client:MSBClient){
        let HRhandler = {[weak self](hrData:MSBSensorHeartRateData!,handlerror:NSError!) in
            if let weakSelf = self {
                self!.hr = Int(bitPattern:hrData.heartRate)
                let hrQuality:String = self!.qualityToString(hrData)
                let now = NSDate()
                weakSelf.HRtext.text = "HR : " + hrData.heartRate.description
                
                //HRの永続化

                //HRを取得し続ける
                do{
                    try weakSelf.client?.sensorManager.startHeartRateUpdatesToQueue(nil, withHandler: {
                        [weak self](HrData : MSBSensorHeartRateData!,hrError:NSError!)in})
                }catch{
                }
            }
            if handlerror != nil{
                print("handleのエラー:")
                print(handlerror.description)
            }
        }
        do{
            try self.client?.sensorManager.startHeartRateUpdatesToQueue(nil, withHandler: HRhandler)
        }catch let error as NSError{
            print(error.description)
        }
        let startHRselector:Selector = #selector(ViewController.startHeartRateUpdates)
        //self.performSelector(startHRselector, withObject: nil, afterDelay: 5)
        NSTimer.scheduledTimerWithTimeInterval(5,target: self,selector: startHRselector,userInfo: nil,repeats: true)
    }
    
    func stopHeartRateUpdates(){
        do{
            try self.client?.sensorManager.stopHeartRateUpdatesErrorRef()
        }catch{
        }
    }

    //GSR
    func startGSRUpdates(){
        let GSRhandler = {[weak self](gsrData:MSBSensorGSRData!,gsrError:NSError!)in
            if let weakSelf = self {
                self!.gsr = Int(bitPattern:gsrData.resistance)
                let now = NSDate()
                weakSelf.GSRtext.text = "GSR : " + self!.gsr.description

                //GSRの永続化
            }
            
        }
        
        do{
            try self.client?.sensorManager.startGSRUpdatesToQueue(nil, withHandler: GSRhandler)
        }catch let error as NSError{
            print(error.description)
        }
        let startGSRselector:Selector = #selector(ViewController.startGSRUpdates)
        self.performSelector(startGSRselector, withObject: nil, afterDelay: 3)
    }
    
    func stopGSRUpdates(){
        do{
            try self.client?.sensorManager.stopGSRUpdatesErrorRef()
        }catch{
        }
    }
    
    func startAccelermaterUpdates(){
        let Acchandler = {[weak self](accData:MSBSensorAccelerometerData!,accError:NSError!)in

            self!.accX = accData.x
            self!.accY = accData.y
            self!.accZ = accData.z
            self!.accS = sqrt(accData.x*accData.x + accData.y*accData.y + accData.z*accData.z)
            let now = NSDate()
            
            if let weakSelf = self {
                weakSelf.accXtext.text = "AccX : " + self!.accX.description
                weakSelf.accYtext.text = "AccY : " + self!.accY.description
                weakSelf.accZtext.text = "AccZ : " + self!.accZ.description
            }
            
            //ACCの永続化
            
        }
        //３分ごとに取得。
        do{
            try self.client?.sensorManager.startAccelerometerUpdatesToQueue(nil, withHandler: Acchandler)
        }catch let error as NSError{
            print(error.description)
        }
        let startAccselector:Selector = #selector(ViewController.startAccelermaterUpdates)
        self.performSelector(startAccselector, withObject: nil, afterDelay: 3)
    }
    
    func stopAccelermaterUpdates(){
        do{
            try self.client?.sensorManager.stopAccelerometerUpdatesErrorRef()
        }catch{
        }
    }
    
    //locationdata
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation){
        latitude = newLocation.coordinate.latitude
        longitude = newLocation.coordinate.longitude
        let now = NSDate()
        self.latitudeText.text = "latitude : " + latitude.description
        self.longitudeText.text = "longitude : " + longitude.description
        
        //Locationの永続化
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("位置情報取得Error!")
    }

}
    
    



    

    
    
    



