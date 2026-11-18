//
//  MessageModel.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import Foundation

struct Message: Codable {
    let messageId: String
    let subject: String
    let messageImageURLs: [String]
    let messageVideoURLs: [String]
    let messageGIFMedia: [String: String]
    let conversationId: String
    let senderId: String
    let senderName: String
    let senderImage: String
    let createdAt: String
    let readStatus: String
    
}
