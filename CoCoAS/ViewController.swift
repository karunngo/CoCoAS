//
//  ViewController.swift
//  CoCoAS
//
//  Created by orihara ayami on 2016/12/31.
//  Copyright © 2016年 orihara ayami. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire

class ViewController:UIViewController,UITextFieldDelegate,MSBClientManagerDelegate,MSBClientTileDelegate,CLLocationManagerDelegate{
    var client:MSBClient? = nil
    
    //Tileのレイアウト
    let TILEID:NSUUID = NSUUID.init(UUIDString: "CABDBA9F-12FD-47A5-8453-E7270A43BB98")!
    let YESNum:UInt16 = 11
    let NoNum:UInt16 = 12
    
    //通知判定
    var doNotification:Bool = false;

    //生体データ
    var hr:Int = 0
    var hrQuality:String = "";
    var gsr:Int = 0
    var accX:Double = 0.0
    var accY:Double = 0.0
    var accZ:Double = 0.0
    var accS:Double = 0.0
    
    //位置データ取得
    var clmanager: CLLocationManager!
    var latitude: CLLocationDegrees!
    var longitude: CLLocationDegrees!
    
    //ユーザ情報
    var userName:String? = nil
    
    //各データのパスとcsvの一行目
    var lifelogDataPath = ""
    var labelDataPath = ""
    var notifiDataPath = ""
    let lifelogDataColumn = "date,hr,hrQuality,gsr,accx,accy,accz,accs,lati,longi\n"
    let labelDataColumn = "date,label\n"
    let notifiDataColumn = "date\n"
    
    //最後に通知を行った時刻
    var lastNotifiDate:NSDate? = nil
    
    
    
    //View
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var HRtext: UILabel!
    @IBOutlet weak var GSRtext: UILabel!
    @IBOutlet weak var accXtext: UILabel!
    @IBOutlet weak var accYtext: UILabel!
    @IBOutlet weak var accZtext: UILabel!
    @IBOutlet weak var latitudeText: UILabel!
    @IBOutlet weak var longitudeText: UILabel!
    
    @IBOutlet weak var nameBox: UITextField!
    
    let userDefalut = NSUserDefaults.standardUserDefaults()
    
    
    
    //MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.message.text="CoCoASにようこそ!"
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        //UserNameの設定
        nameBox.delegate = self
        if let nameText = userDefalut.stringForKey("userName"){
            nameBox.text = nameText
            self.userName = nameText
        }
        
        
        //データ保存用のファイルパス
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)[0] as String
        self.lifelogDataPath = path + "/lifelog.csv"
        self.labelDataPath = path + "/label.csv"
        self.notifiDataPath = path + "/notification.csv"
        
        //各データ保存用のファイルが存在するか確認
        let checkValidation:NSFileManager = NSFileManager.defaultManager()
        
        if (checkValidation.fileExistsAtPath(self.lifelogDataPath) == false) {
            print(self.lifelogDataPath + "は存在しません。ファイルを作ります");
            do{
                try self.lifelogDataColumn.writeToFile(self.lifelogDataPath, atomically: true, encoding: NSUTF8StringEncoding)
            }catch let error as NSError{
                print("lifelog.csvファイル作成失敗　error:"+error.description)
            }
        }
        
        if (checkValidation.fileExistsAtPath(self.labelDataPath) == false) {
            print(self.labelDataPath + "は存在しません。ファイルを作ります");
            do{
                try self.labelDataColumn.writeToFile(self.labelDataPath, atomically: true, encoding: NSUTF8StringEncoding)
            }catch let error as NSError{
                print("label.csvファイル作成失敗　error:"+error.description)
            }
        }
        
        if (checkValidation.fileExistsAtPath(self.notifiDataPath) == false) {
            print(self.notifiDataPath + "は存在しません。ファイルを作ります");
            do{
                try self.lifelogDataColumn.writeToFile(self.notifiDataPath, atomically: true, encoding: NSUTF8StringEncoding)
            }catch let error as NSError{
                print("notification.csvファイル作成失敗　error:"+error.description)
            }
        }

        
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
    
    //MARK: 画面のリスナー
    //TextBoxのEnterが押されたら、保存
    @IBAction func didEndEditName(sender: AnyObject) {
        self.userName = nameBox.text
        if let newName = nameBox.text{
            userDefalut.setObject(NSString(UTF8String: newName), forKey: "userName")
        }
    }
    
    //通信テストボタン
    @IBAction func didTapSendData(sender: AnyObject) {
        postTimer()
    }
    
    //MARK:定期的な保存&送信
    func saveTimer(){
        //現在時刻取得(CSVにするにあたり、String化)
        print("saveTimer動いてるよ！")
        let now = NSDate()
        
        //lifelogDataColumn:date,hr,hrquality,gsr,accx,accy,accz,accs,lati,longi
        let nowString = self.dateToStrint(now)
        let hrS:String = String(self.hr) + "," + self.hrQuality
        let gsrS:String = String(self.gsr)
        let acc4:String = String(self.accX) + "," + String(self.accY) + "," + String(self.accZ) + "," + String(self.accS)
        let locateS:String = String(self.latitude) + "," + String(self.longitude)
        let saveData:String = nowString + "," + hrS + "," + gsrS + "," + acc4 + "," + locateS + "\n"
        print("saveData=" + saveData)
        
        self.appendToCSV(self.lifelogDataPath, data: saveData)
        
    }
    
    func postTimer(){
        //ファイル中身
        
        //POST送信
            postData(self.lifelogDataPath, fileName: "lifelogData")
            postData(self.labelDataPath, fileName: "labelData")
            postData(self.notifiDataPath, fileName: "notifiData")
    
    }
    
    func postData(dataPath:String,fileName:String){
        print("データをPOSTします")
        let dataURL = NSURL(fileURLWithPath:dataPath)
        if let sendUserName = self.userName{
            Alamofire.upload(.POST, "http://life-cloud.ht.sfc.keio.ac.jp/~karu/cocoas/Cocoas.php",
                             multipartFormData: { multipartFormData in
                                //csvデータをそのまま送る
                                multipartFormData.appendBodyPart(data:sendUserName.dataUsingEncoding(NSUTF8StringEncoding)!,name:"user_name")
                                multipartFormData.appendBodyPart(data:fileName.dataUsingEncoding(NSUTF8StringEncoding)!,name:"type")
                                multipartFormData.appendBodyPart(fileURL:dataURL,name:"data",fileName:fileName + ".csv",mimeType:"text/plain")
                                },
                             encodingCompletion:{ encodingResult in
                                switch encodingResult{
                                    case .Success(let upload, _, _):
                                        upload.response{ (request, response, data, error) in
                                            if (response?.statusCode == 200) {
                                                //通信が成功したらファイルのクリーンアップ
                                                //FIXME: サーバからの返答に応じて削除するか判断する(今は保存出来てなくともファイルを消してる。危険）
                                                print(fileName + "のデータを送りました")
                                                self.fileCleanup(fileName)
                                            } else {
                                                print(fileName + "の送信に失敗しました")
                                                if let errorCode = response?.statusCode{
                                                    print("エラーコード:" + String(errorCode))
                                                }else{
                                                    print("エラーコードは無し")
                                                }
                                            }
                                    
                                        }
                                        break;
                                    
                                    case .Failure(let encodingError):
                                        print("エンコード失敗。エラー:")
                                        print(encodingError)
                                        break;
                                }
                            })
        }
    }
    
    
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
        
        //保存と送信の開始
        print("start save & post!")
        let saveSelector:Selector = #selector(ViewController.saveTimer)
        let postSelector:Selector = #selector(ViewController.postTimer)
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: saveSelector, userInfo: client, repeats: true)
        NSTimer.scheduledTimerWithTimeInterval(60*10, target: self, selector: postSelector, userInfo: client, repeats: true)
    }
    

    //MARK: -
    //MARK:MSBandTileの初期化
    //MSBandのタイルのレイアウトを定義
    //FIXME: 評価はYES,NOでいいのか。文言はこれでいいのか(先行研究調べられてない…)
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
    //FIXME: ランダムor定時版を作る
    func sendNotificationToBand(client:MSBClient){
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0)) {
            while(true){
                if self.doNotification{
                    var allowNotification:Bool = false;
                    let now = NSDate()
                    let nowString = self.dateToStrint(now)
                    var startNotification:NSDate? = nil
                    
                    //直前の通知＋30分後を調べる。今の時刻がそれよりあとなら、通知をする
                    //最終通知時刻があれば、通知を再開する時刻startNotifiを決定。
                    if let  lastNoti = self.lastNotifiDate{
                        startNotification = NSDate(timeInterval: 60*30, sinceDate:lastNoti)//nowを直前通知時刻にすること。
                    }
                    //startNotificationが定義されてれば、現在時刻と比較し判定。nilなら通知許可
                    if let startNoti = startNotification{
                        if now.compare(startNoti) == .OrderedAscending{
                            allowNotification = true
                        }
                    }else{
                        allowNotification = true
                    }
                    
                    if self.judgeStress() && allowNotification {
                        print("judgeStressがスタート")
                        let tileString = "Are You Stressed?"
                        let bodyString = "Please labeled." //+ 現在時刻
                        client.notificationManager.showDialogWithTileID(self.TILEID, title: tileString, body: bodyString, completionHandler:{
                            (sendError) in
                            if(sendError == nil){
                                print("送るの成功")
                                self.doNotification = false
                                self.appendToCSV(self.notifiDataPath, data: nowString + "\n")
                                print("falseになったよ")
                                
                            }else{
                                print(sendError.description)
                            }
                        })
                        self.lastNotifiDate = now
                        self.doNotification = false
                    }
                    sleep(500)
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                // 上でさせた作業でUI機能が呼ばれた時
            }
        }

    }
    
    //ストレスがあるかの仮判定
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
        //ラベルを取得しcsvに保存
        var labelString = "";
        let nowButton = event.buttonId
        print(nowButton)
        if nowButton == YESNum {
            labelString = "YES"
        }else if nowButton == NoNum {
            labelString = "NO"
        }else{
            labelString = "Error"
        }
        
        let now = NSDate()
        let nowString = self.dateToStrint(now)
        let saveData:String = nowString + "," + labelString + "\n"
        self.appendToCSV(self.notifiDataPath, data: saveData)
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
    
    //データベースに書き込む(前のデータを一旦読み込み、追加して再度書き込み)
    func appendToCSV(path:String,data:String){
        var csvData:String = "";
        var newCsvData:String = "";
        do{
            try csvData = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
            newCsvData = csvData + data + "\n"
            do{
                try newCsvData.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
            }catch let error1 as NSError{
                print("データベースへの書き込み失敗" + error1.description)
            }
        }catch let error as NSError{
            print("ファイルの読み込み失敗" + error.description)
        }
        
    }
    
    //現在時刻をStringで書き出す
    func dateToStrint(date:NSDate)->String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.stringFromDate(date)
    }
    
    func dateFromString(dateString:String) -> NSDate {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.dateFromString(dateString)!
    }

    //ファイルをクリーンアップする
    func fileCleanup(file_name: String) {
        
        print("Cleaning " + file_name + " File.")
        let cleanData:String = ""
        var cleanPath:String = ""
        
        switch file_name {
        case "lifelogData":
            cleanPath = self.lifelogDataPath
            break;
        case "labelData":
            cleanPath = self.labelDataPath
            break;
        case "notifiData":
            cleanPath = self.notifiDataPath
        default:
            print("不明のfileCleanup")
        }
        
        do{
            try cleanData.writeToFile(cleanPath, atomically: true, encoding: NSUTF8StringEncoding)
        }catch{
        }

        
    }
    
    
    
    
    //MARK: -
    //MARK:ライフログデータ取得
    //HR
    func startHeartRateUpdates(client:MSBClient){
        let HRhandler = {[weak self](hrData:MSBSensorHeartRateData!,handlerror:NSError!) in
            if let weakSelf = self {
                self!.hr = Int(bitPattern:hrData.heartRate)
                self!.hrQuality = self!.qualityToString(hrData)
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
    
    



    

    
    
    



