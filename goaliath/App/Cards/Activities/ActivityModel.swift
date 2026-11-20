//
//  ActivityModel.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import Foundation

struct Activity: Codable {
    // V4 canonical media arrays; optional for backwards-compatible decoding.
    var image_urls: [String]? = nil
    var video_urls: [String]? = nil
    var gif_urls: [String]? = nil

    let activityId: String
    let title: String
    let date: String
    let startTime: String
    let endTime: String
    let location: String
    let description: String
    let mainImageUrl: String
    let activityType: String
    let activityMeals: [SuggestedMeal]
    let activityWorkout: [Workout]
    let activityTask: [Task]
    let status: String
    let creatorId: String
    let viewedByUser: Bool

}
