//
//  UserStatusModel.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import Foundation

struct UserStatus: Codable {
    
    var userId: String
    var username: String
    var firstName: String
    var lastName: String
    var phone: String
    var joined: String
    var userImageURL: String
    var statusType: String
    var userStatusImageURLs: [String]
    var userStatusVideoURLs: [String]
    var userStatusGIFMedia: [String: String]
    var userStatusDate: String
    var userStatusTitle: String
    var userStatusDescription: String

}
