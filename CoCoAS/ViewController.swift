//
//  ViewController.swift
//  CoCoAS
//
//  Created by orihara ayami on 2016/12/31.
//  Copyright © 2016年 orihara ayami. All rights reserved.
//

import UIKit


class ViewController:UIViewController,MSBClientManagerDelegate,MSBClientTileDelegate{
    var client:MSBClient? = nil;
    let TILEID:NSUUID = NSUUID.init(UUIDString: "CABDBA9F-12FD-47A5-8453-E7270A43BB99")!;
    
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var HRtext: UILabel!
    @IBOutlet weak var GSRtext: UILabel!
    @IBOutlet weak var accXtext: UILabel!
    @IBOutlet weak var accYtext: UILabel!
    @IBOutlet weak var accZtext: UILabel!
    @IBOutlet weak var latitudeText: UILabel!
    @IBOutlet weak var longitudeText: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.message.text="CoCoASにようこそ!";
        //TODO:set CoreDataManager
        
        //test
    
        //connect Band
        MSBClientManager.sharedManager().delegate=self;
        
        let clients:NSArray = MSBClientManager.sharedManager().attachedClients();
        if clients.firstObject == nil{
            self.message.text="Clientsが空だよ！";
            return
        }
        self.client = clients.firstObject as? MSBClient;
        if self.client == nil{
            self.message.text="Failed! No Bands attached.";
        }
        MSBClientManager.sharedManager().connectClient(self.client);
        self.message.text="Please wait. Connecting to Band ";
        
        //TODO:create tile on Band
        self.client?.tileDelegate = self;
        
        
        
        //TODO:start get lifelogs
        
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tileWithButtonLayout()->MSBPageData{
        let tileName:String = "CoCoAS Tile";
        var tile:MSBTile? = nil;
        //create tile icon
        do{
        let tileIcon:MSBIcon = try MSBIcon.init(UIImage: UIImage.init(named: "Stress.png")!)
        let smallIcon:MSBIcon = try MSBIcon.init(UIImage: UIImage.init(named: "StressS.png")!)
        tile = try MSBTile.init(id: TILEID, name: tileName, tileIcon: tileIcon, smallIcon: smallIcon)
        }catch{
        }
        
        //create a textBox
        var textBlock = MSBPageTextBlock.init(rect: MSBPageRect.init(x: 0, y: 0, width: 200, height: 400), font: MSBPageTextBlockFont.Small)
        textBlock.baseline = 25
        textBlock.baselineAlignment = MSBPageTextBlockBaselineAlignment.Relative
        textBlock.horizontalAlignment = MSBPageHorizontalAlignment.Center
        textBlock.autoWidth = false
        textBlock.margins = MSBPageMargins.init(left: 5, top: 2, right: 5, bottom: 2)
        //create a TextButton
        var buttonYes = MSBPageTextButton.init(rect: MSBPageRect.init(x: 0, y: 0, width: 100, height: 40))
        buttonYes.elementId = 11
        buttonYes.horizontalAlignment = MSBPageHorizontalAlignment.Center
        buttonYes.margins = MSBPageMargins.init(left: 5, top: 2, right: 5, bottom: 2)
        
        var buttonNo = MSBPageTextButton.init(rect: MSBPageRect.init(x: 0, y: 0, width: 100, height: 40))
        buttonNo.elementId = 12
        buttonNo.horizontalAlignment = MSBPageHorizontalAlignment.Center
        buttonNo.margins = MSBPageMargins.init(left: 5, top: 2, right: 5, bottom: 2)
        
        //レイアウト作る
    }
    
    //MARK:-
    //MARK: Helper methods
    func seveCoreData(){
        
    }
    
    
    

    //MARK: -
    //MARK:Notification manage
    func sendNotificationToBand(client:MSBClient){
        
        if judgeStress() {
            var now = NSDate();
            var tileString = "Are You Stressed?";
            var bodyString = "Please labeled."; //+ 現在時刻
            //TODO:通知する
            //FIXME:weakにする？selfにした方がよい？
            //client.notificationManager.showDialogWithTileID(tileID, title: tileString, body: bodyString, completionHandler:<#T##((NSError!) -> Void)!##((NSError!) -> Void)!##(NSError!) -> Void#>);
            
            //TODO:通知した時刻を保存
            
            //TODO:一度通知したらしばらく繰り返さない
        }

    }
    
    func judgeStress() -> Bool{
    var isStress:Bool = false;
        //ここでストレスがあるか判定
        return isStress;
    }
    
    
    //MARK: -
    //MARK:LifelogDatasUpdate
    //TODO:HRの追加
    //TODO:GSRの追加
    //TODO:加速度の追加
    func startHeartRateUpdates(client:MSBClient){
        
    }
    
    func stopHeartRateUpdates(){
        
    }
    
    
    //MARK: -
    //MARK:MSBClitentTileDelegate
    func client(client: MSBClient!, tileDidOpen event: MSBTileEvent!) {
        
        
    }
    
    func client(client: MSBClient!, tileDidClose event: MSBTileEvent!) {
        
    }
    
    func client(client: MSBClient!, buttonDidPress event: MSBTileButtonEvent!) {
        //Bandへの通知(取得できたよありがとう)
        //ラベル・時刻を取得
        //DBに保存
        
    }
    
    //MARK:MSBClientManagerDelegate
    func clientManager(clientManager: MSBClientManager!, clientDidConnect client: MSBClient!) {
        
    }
    
    func clientManager(clientManager: MSBClientManager!, clientDidDisconnect client: MSBClient!) {
        //再接続
        MSBClientManager.sharedManager().connectClient(self.client);
    }
    
    func clientManager(clientManager: MSBClientManager!, client: MSBClient!, didFailToConnectWithError error: NSError!) {
        //再接続
        MSBClientManager.sharedManager().connectClient(self.client);
        
    }
    
    
    

}

