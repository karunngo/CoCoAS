//
//  RealmData.swift
//  CoCoAS
//
//  Created by orihara ayami on 2017/01/10.
//  Copyright © 2017年 orihara ayami. All rights reserved.
//

import RealmSwift

class RealmLabel: Object {
    dynamic var date:NSData? = nil
    dynamic var name:String = ""
}

class User2: Object {
    dynamic var id = 1
    dynamic var name = ""
}
