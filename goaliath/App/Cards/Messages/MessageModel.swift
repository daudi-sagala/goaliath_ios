//
//  MessageModel.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import Foundation

struct Message: Codable {
    // V4 canonical media arrays; optional for backwards-compatible decoding.
    var image_urls: [String]? = nil
    var video_urls: [String]? = nil
    var gif_urls: [String]? = nil

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
