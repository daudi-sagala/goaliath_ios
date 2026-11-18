//
//  ActivityModel.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import Foundation

struct Activity: Codable {
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
