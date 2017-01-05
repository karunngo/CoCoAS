//
//  ViewController.swift
//  CoCoAS
//
//  Created by orihara ayami on 2016/12/31.
//  Copyright © 2016年 orihara ayami. All rights reserved.
//

import UIKit


class ViewController:UIViewController,MSBClientManagerDelegate,MSBClientTileDelegate{
    var client:MSBClient? = nil
    let TILEID:NSUUID = NSUUID.init(UUIDString: "CABDBA9F-12FD-47A5-8453-E7270A43BB98")!
    
    var doNotification:Bool = false;

    //stress判定で使うために生体データの値をグローバルに
    var hr:UInt? = nil;
    
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
        //TODO:set CoreDataManager
        
        //test
    
        //connect Band
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
        
        //TODO:start get lifelogs
        
        
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
        
        //create a textBox
        let textBlock = MSBPageTextBlock.init(rect: MSBPageRect.init(x: 0, y: 0, width: 200, height: 400), font: MSBPageTextBlockFont.Small)
        textBlock.elementId = 10
        textBlock.baseline = 25
        textBlock.baselineAlignment = MSBPageTextBlockBaselineAlignment.Relative
        textBlock.horizontalAlignment = MSBPageHorizontalAlignment.Center
        textBlock.autoWidth = false
        textBlock.margins = MSBPageMargins.init(left: 5, top: 2, right: 5, bottom: 2)
        
        //create a TextButton
        let buttonYes = MSBPageTextButton.init(rect: MSBPageRect.init(x: 0, y: 0, width: 100, height: 40))
        buttonYes.elementId = 11
        buttonYes.horizontalAlignment = MSBPageHorizontalAlignment.Center
        buttonYes.margins = MSBPageMargins.init(left: 5, top: 2, right: 5, bottom: 2)
        
        let buttonNo = MSBPageTextButton.init(rect: MSBPageRect.init(x: 0, y: 0, width: 100, height: 40))
        buttonNo.elementId = 12
        buttonNo.horizontalAlignment = MSBPageHorizontalAlignment.Center
        buttonNo.margins = MSBPageMargins.init(left: 5, top: 2, right: 5, bottom: 2)
        
        do{
        try buttonYes.pressedColor = MSBColor.init(UIColor:UIColor.redColor())
        try buttonNo.pressedColor = MSBColor.init(UIColor:UIColor.cyanColor())
        }catch{
        print("buttonの色かわらず！")}
        
        //set on panel
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
        print("pageDatesを返すよ：")
        return pageDatas
    }

    
    //MARK:-
    //MARK: Helper methods
    func seveCoreData(){
        
    }
    
    
    
    

    //MARK: -
    //MARK:Notification manage
    func sendNotificationToBand(client:MSBClient){
        while(self.doNotification){
            print("judgeStress手前")
            if judgeStress() {
                var now = NSDate()
                var tileString = "Are You Stressed?"
                var bodyString = "Please labeled." //+ 現在時刻
                //TODO:通知する
                client.notificationManager.showDialogWithTileID(TILEID, title: tileString, body: bodyString, completionHandler:{
                    (sendError) in
                    if(sendError != nil){
                        print("Send dialog!")
                        //TODO:通知した時刻を保存
                        self.doNotification = false
                        //5分止める
                        
                        
                    }else{
                        print("sendDialogError!:")
                        print(sendError.description)
                    }
                })
            }
            sleep(5)
        }

    }
    
    func judgeStress() -> Bool{
    var isStress:Bool = false
        //ここでストレスがあるか判定
        if self.hr > 65{
            isStress = true
        }
        return isStress
    }
    
    
    //MARK: -
    //MARK:LifelogDatasUpdate
    //HR
    func startHeartRateUpdates(client:MSBClient){
        let HRhandler = {[weak self](heartRateData:MSBSensorHeartRateData!,handlerror:NSError!) in
            //ここに中身を書く？
            if let weakSelf = self {
                self!.hr = heartRateData.heartRate
                var hrQuality = heartRateData.quality
                let now = NSDate()
                print(heartRateData.heartRate.description)
                weakSelf.HRtext.text = "HR : " + heartRateData.heartRate.description + ":" + now.description
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
        self.performSelector(startHRselector, withObject: nil, afterDelay: 5)
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
                var gsr = gsrData.resistance
                let now = NSDate()
                weakSelf.GSRtext.text = "GSR : " + gsr.description + ":" + now.description
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
    //TODO:加速度の追加
    func startAccelermaterUpdates(){
        let Acchandler = {[weak self](accData:MSBSensorAccelerometerData!,accError:NSError!)in
            if let weakSelf = self {
                var accX = accData.x
                var accY = accData.y
                var accZ = accData.z
                var accS = sqrt(accX*accX + accY*accY + accZ*accZ)
                let now = NSData()
                weakSelf.accXtext.text = "AccX : " + accX.description
                weakSelf.accYtext.text = "AccY : " + accY.description
                weakSelf.accZtext.text = "AccZ : " + accZ.description
                
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
    //MARK:MSBClientManagerDelegate
    func clientManager(clientManager: MSBClientManager!, clientDidConnect client: MSBClient!) {
        print("client did connected!!")
        self.client!.tileDelegate = self
        //TODO: create the page on tile
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
        //TODO: start to get lifelog
        
         if self.client?.sensorManager.heartRateUserConsent() == MSBUserConsent.Granted{
         startHeartRateUpdates(self.client!)
         }else{
         self.message.text = "Requesting user consent for accessing HeartRate..."
         self.client?.sensorManager.requestHRUserConsentWithCompletion(
         {[weak self](userConsent:Bool,err:NSError!) -> Void in
         if let weakSelf = self {
         if(userConsent){
         weakSelf.startHeartRateUpdates(weakSelf.client!)
         }else{
         weakSelf.HRtext.text = "User consent declined";
         }
         }
         })
         }
         
         self.startGSRUpdates()
         self.startAccelermaterUpdates()
         
        
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
        //Bandへの通知(取得できたよありがとう)
        print("pressed button!")
        var tileString = "Thank you!"
        var bodyString = "You labeled.Please go back." //+ 現在時刻
        //TODO:通知する
        client.notificationManager.showDialogWithTileID(TILEID, title: tileString, body: bodyString, completionHandler: {
            (didPressError) in
            if didPressError != nil{
                print (didPressError.description)
            }
        })
        //ラベルを取得
        var nowButton:String = event.buttonId.description
        print(nowButton)
        //DBに保存
        
    }
    

    
    
    

}

