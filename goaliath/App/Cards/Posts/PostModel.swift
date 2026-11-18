//
//  PostModel.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import Foundation

struct Post: Codable {
    let postId: String
    let postType: String
    let subject: String
    let postMainMediaURL: String
    let postMainMediaType: String
    let postMediaCount: Int
    let postImageURLs: [String]
    let postVideoURLs: [String]
    let postGIFMedia: [String: String]
    let posterId: String
    let posterName: String
    let posterImageURL: String
    let posterLocation: String
    let posterRole: String
    let posterConversationId: String
    let createdAt: String
    let updatedAt: [String]
    let expiresAt: String
    let status: [String]
    let tags: [String]
    let responderImageUrls: [String]
    let postResponseCount: Int
    let postSavedCount: Int
    let savedPostStatus: String
    let postSelectedMealIds: [String]
    let postWorkoutIds: [String]
    let postActivityIds: [String]
    let postTaskIds: [String]
    
}
