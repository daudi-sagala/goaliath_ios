//
//  Task.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//


struct Task: Codable {
    // V4 canonical media arrays; optional for backwards-compatible decoding.
    var image_urls: [String]? = nil
    var video_urls: [String]? = nil
    var gif_urls: [String]? = nil

    let taskId: String
    let title: String
    let description: String
    let createdBy: String
    let createdAt: String
    let taskImageUrls: [String]
    let taskVideoUrls: [String]
    let taskGIFMedia: [String: String]
    
}
