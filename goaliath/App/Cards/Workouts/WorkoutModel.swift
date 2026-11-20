//
//  Workout.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//
import Foundation


struct Workout: Codable {
    // V4 canonical media arrays; optional for backwards-compatible decoding.
    var image_urls: [String]? = nil
    var video_urls: [String]? = nil
    var gif_urls: [String]? = nil

    let workoutId: String
    let workoutImageUrls: [String]
    let workoutTitle: String
    let workoutLocation: String
    let workoutCategories: [String]
    let selectedWorkoutTime: String
    let workoutDurationInSeconds: Int
    let workoutDurationText: String
    let workoutDescription: String
    let workoutDistance: String
    let workoutTrainer: Trainer
    let workoutStatus: String
    let workoutCommentsCount: Int
    let lastComment: WorkoutComment
    let participants: [WorkoutParticipant]
    let workoutFormat: String
    let rating: String
    let createdAt: String
    let user: User
    struct User: Codable {
        let userId: String
        let name: String
        let location: String
        let avatarURL: String
    }
    
}


struct Trainer: Codable, Equatable {
    let userId: String
    let name: String
    let location: String
    let userImageUrl: String
    let userDescription: String
    let conversationId: String
    let onlineStatus: String
    let rating: String
    
}

struct WorkoutParticipant: Codable, Equatable {
    let userId: String
    let name: String
    let userImage: String
    let userLocation: String
    let userRole: String
    let userBio: String
    let userConversationId: String
    let userStatus: String
    let statusDescription: String
    let nearestActivityTime: String // closest past/upcoming session by user
    let nearestActivityId: String // closest past/upcoming session's activity id by user
    
}

struct WorkoutComment: Codable {
    let commentId: String
    let userId: String
    let name: String
    let userImage: String
    let userLocation: String
    let userRole: String
    let userBio: String
    let userConversationId: String
    let userStatus: String
    let commentText: String
    let createdAt: String
    let workoutId: String
    
}
