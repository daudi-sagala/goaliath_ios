//
//  GiftModel.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import Foundation


struct Gift: Codable {
    let giftId: String
     let tokenCount: Int
     let giftGiver: GiftGiver
     let giftReceiver: GiftReceiver
     let giftDate: String
     let status: [String]
     let giftMessage: String
     let modifiedAt: [String]
    
}

struct GiftGiver: Codable {
    var userId: String
    var username: String
    var firstName: String
    var lastName: String
    var userImageURL: String
}


struct GiftReceiver: Codable {
    var userId: String
    var username: String
    var firstName: String
    var lastName: String
    var userImageURL: String
}
