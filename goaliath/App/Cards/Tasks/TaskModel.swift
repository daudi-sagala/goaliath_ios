//
//  Task.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//


struct Task: Codable {
    let taskId: String
    let title: String
    let description: String
    let createdBy: String
    let createdAt: String
    let taskImageUrls: [String]
    let taskVideoUrls: [String]
    let taskGIFMedia: [String: String]
    
}
