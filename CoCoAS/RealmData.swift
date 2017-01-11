//
//  RealmData.swift
//  CoCoAS
//
//  Created by orihara ayami on 2017/01/10.
//  Copyright © 2017年 orihara ayami. All rights reserved.
//

import RealmSwift

class RealmLabel: Object {
    dynamic var date:NSDate? = nil
    dynamic var name:String = ""
}

class RealmHR: Object {
    dynamic var date:NSDate? = nil
    dynamic var quality:String = ""
    dynamic var hr:Int = 0
}

class RealmGSR: Object {
    dynamic var date:NSDate? = nil
    dynamic var gsr:Int = 0
}
