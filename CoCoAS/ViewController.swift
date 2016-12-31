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
    let tileID:NSUUID = NSUUID.init(UUIDString: "CABDBA9F-12FD-47A5-8453-E7270A43BB99")!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //setView
        
        
        //setCoreDataManager
        
        
        //connect Band
        let clients:NSArray = MSBClientManager.sharedManager().attachedClients();
        self.client = clients.firstObject as? MSBClient;
        if self.client == nil{
            //エラーメッセージ表示
        }
        MSBClientManager.sharedManager().connectClient(self.client);
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    

    //MARK:send notification to Band
    func sendNotificationToBand(client:MSBClient){
        
        if judgeStress() {
            let now = NSDate();
            let tileString = "Are You Stressed?";
            let bodyString = "Please labeled."; //+ 現在時刻
            //ここで通知する(weakにしたほうがよい？selfにした方がよい？
            client.notificationManager.showDialogWithTileID(tileID, title: tileString, body: bodyString, completionHandler: <#T##((NSError!) -> Void)!##((NSError!) -> Void)!##(NSError!) -> Void#>);
            
            //通知した時刻を保存
        }

    }
    
    func judgeStress() -> Bool{
    var isStress:Bool = false;
        //ここでストレスがあるか判定
        return isStress;
    }
    
    
    
    //MARK:LifelogDatasUpdate
    
    func startHeartRateUpdates(client:MSBClient){
        
    }
    
    func stopHeartRateUpdates(){
        
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
    
    
    

}

