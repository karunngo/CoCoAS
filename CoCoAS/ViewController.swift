//
//  ViewController.swift
//  CoCoAS
//
//  Created by orihara ayami on 2016/12/31.
//  Copyright © 2016年 orihara ayami. All rights reserved.
//

import UIKit
import CoreLocation
import RealmSwift

class ViewController:UIViewController,MSBClientManagerDelegate,MSBClientTileDelegate,CLLocationManagerDelegate{
    var client:MSBClient? = nil
    
    //Tileのレイアウト
    let TILEID:NSUUID = NSUUID.init(UUIDString: "CABDBA9F-12FD-47A5-8453-E7270A43BB98")!
    let YESNum:UInt16 = 11
    let NoNum:UInt16 = 12
    
    //通知判定
    var doNotification:Bool = false;

    //stress判定
    var hr:Int = 0;
    
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
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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

    
    //MARK:-
    //MARK: Helper methods
    //HRQualityをStringで返す
    func qualityToString(hrData:MSBSensorHeartRateData!)->String{
        switch hrData.quality {
        case MSBSensorHeartRateQuality.Acquiring:
            return "Acquiring"
        case MSBSensorHeartRateQuality.Locked:
            return "Locked"
        }
    }
    //realmのデータを全削除(デバック用)
    func resetRealm(){
        let realmURL = Realm.Configuration.defaultConfiguration.fileURL!
        let realmURLs = [
            realmURL,
            realmURL.URLByAppendingPathExtension("lock"),
            ]
        print(realmURLs)
        let manager = NSFileManager.defaultManager()
        for URL in realmURLs {
            do {
                try manager.removeItemAtURL(URL!)
            } catch {
                print("エラー！消されてないよ")
            }
        }
    }

    //MARK: -
    //MARK:Notification manage
    func sendNotificationToBand(client:MSBClient){
        while(self.doNotification){
            if judgeStress() {
                var now = NSDate()
                var tileString = "Are You Stressed?"
                var bodyString = "Please labeled." //+ 現在時刻
                //TODO:通知する
                client.notificationManager.showDialogWithTileID(TILEID, title: tileString, body: bodyString, completionHandler:{
                    (sendError) in
                    if(sendError != nil){
                        //TODO:通知した時刻を保存
                        self.doNotification = false
                    }else{
                        print(sendError.description)
                    }
                })
            }
            sleep(5)
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
    //MARK:LifelogDatasUpdate
    //HR
    func startHeartRateUpdates(client:MSBClient){
        let HRhandler = {[weak self](hrData:MSBSensorHeartRateData!,handlerror:NSError!) in
            if let weakSelf = self {
                self!.hr = Int(bitPattern:hrData.heartRate)
                let hrQuality:String = self!.qualityToString(hrData)
                let now = NSDate()
                weakSelf.HRtext.text = "HR : " + hrData.heartRate.description
                print(hrData.heartRate.description)
                
                //HRの永続化
                let realmHR = RealmHR()
                realmHR.date = now
                realmHR.quality = hrQuality
                realmHR.hr = self!.hr
                let realm = try! Realm()
                try! realm.write {
                    realm.add(realmHR)
                }
                
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
        
        
        //UIBackgroundTaskIdentifierを使ってみよっと。Timerじゃダメだった
        
    }
    
    func stopHeartRateUpdates(){
        do{
            try self.client?.sensorManager.stopHeartRateUpdatesErrorRef()
        }catch{
        }
        self.HRtext.text="try again..."
        self.startHeartRateUpdates(self.client!);
    }

    //GSR
    func startGSRUpdates(){
        let GSRhandler = {[weak self](gsrData:MSBSensorGSRData!,gsrError:NSError!)in
            if let weakSelf = self {
                let gsr = Int(bitPattern:gsrData.resistance)
                let now = NSDate()
                weakSelf.GSRtext.text = "GSR : " + gsr.description

                //GSRの永続化
                let realmGSR = RealmGSR()
                realmGSR.date = now
                realmGSR.gsr = gsr
                let realm = try! Realm()
                try! realm.write {
                    realm.add(realmGSR)
                }
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
        self.GSRtext.text="try again..."
        self.startGSRUpdates()
    }
    
    func startAccelermaterUpdates(){
        let Acchandler = {[weak self](accData:MSBSensorAccelerometerData!,accError:NSError!)in

            let accX = accData.x
            let accY = accData.y
            let accZ = accData.z
            let accS = sqrt(accX*accX + accY*accY + accZ*accZ)
            let now = NSDate()
            
            if let weakSelf = self {
                weakSelf.accXtext.text = "AccX : " + accX.description
                weakSelf.accYtext.text = "AccY : " + accY.description
                weakSelf.accZtext.text = "AccZ : " + accZ.description
            }
            
            //GSRの永続化
            let realmAcc = RealmAcc()
            realmAcc.date = now
            realmAcc.x = accX
            realmAcc.y = accY
            realmAcc.z = accZ
            realmAcc.synthesized = accS
            let realm = try! Realm()
            try! realm.write {
                realm.add(realmAcc)
            }
        }
        
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
        self.accXtext.text = "try again..."
        self.startAccelermaterUpdates()
    }
    
    //locationdata
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation){
        latitude = newLocation.coordinate.latitude
        longitude = newLocation.coordinate.longitude
        let now = NSDate()
        self.latitudeText.text = "latitude : " + latitude.description
        self.longitudeText.text = "longitude : " + longitude.description
        
        //Locationの永続化
        let realmLocation = RealmLocation()
        realmLocation.date = now
        realmLocation.latitude = Double(latitude)
        realmLocation.longitude = Double(longitude)
        let realm = try! Realm()
        try! realm.write {
            realm.add(realmLocation)
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("位置情報取得Error!")
    }
    
    //MARK: -
    //MARK:MSBClientManagerDelegate
    func clientManager(clientManager: MSBClientManager!, clientDidConnect client: MSBClient!) {
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
        /*//start sendNotification
         self.doNotification = true;
         self.sendNotificationToBand(self.client!)
         */
    }
    
    func clientManager(clientManager: MSBClientManager!, clientDidDisconnect client: MSBClient!) {
        //再接続
        MSBClientManager.sharedManager().connectClient(self.client)
    }
    
    func clientManager(clientManager: MSBClientManager!, client: MSBClient!, didFailToConnectWithError error: NSError!) {
        //再接続
        MSBClientManager.sharedManager().connectClient(self.client)
        
    }
    
    
    //MARK: -
    //MARK:MSBClitentTileDelegate
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
        //ラベルを取得し永続化
        let nowButton:String = event.buttonId.description
        print(nowButton)
        
        let now = NSDate()
        let realmLabel = RealmLabel()
        realmLabel.date = now
        realmLabel.name = "test"
        let realm = try! Realm()
        try! realm.write {
            realm.add(realmLabel)
        }
        }
        
        
    }
    

    
    
    



