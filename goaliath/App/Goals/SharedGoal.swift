//
//  SharedGoal.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/9/26.
//

import Foundation



struct SharedGoal: Identifiable {
    let id = UUID()
    let userImageUrl: String
    let userName: String
    let dateAdded: String
    let goalDescription: String
    var category: String = "Personal Growth"
    var peopleCount: Int = 1
}


let sharedGoals: [SharedGoal] = [

    SharedGoal(
        userImageUrl: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1695964846/bots/female_agent_3.jpg",
        userName: "Sophie M.",
        dateAdded: "2h ago",
        goalDescription: "Lose 20 lbs and build a healthier lifestyle. Starting with daily walks and better eating habits.",
        category: "Health & Fitness",
        peopleCount: 248
    ),

    SharedGoal(
        userImageUrl: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1695991791/bots/male_agent_4.jpg",
        userName: "Marcus T.",
        dateAdded: "4h ago",
        goalDescription: "Launch my own business within the next 6 months. Turning an idea I've had for years into something real.",
        category: "Career & Business",
        peopleCount: 86
    ),

    SharedGoal(
        userImageUrl: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1720756243/avatars_collection/ifzg5ldqhrhpd63aza42.png",
        userName: "Emily R.",
        dateAdded: "6h ago",
        goalDescription: "Read 24 books this year. Making more time for learning and less time scrolling.",
        category: "Learning",
        peopleCount: 132
    ),

    SharedGoal(
        userImageUrl: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1695991790/bots/male_agent_2.jpg",
        userName: "Daniel K.",
        dateAdded: "8h ago",
        goalDescription: "Run my first half marathon. Building endurance one run at a time.",
        category: "Health & Fitness",
        peopleCount: 194
    ),

    SharedGoal(
        userImageUrl: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1695964846/bots/female_agent_2.jpg",
        userName: "Olivia B.",
        dateAdded: "1d ago",
        goalDescription: "Learn Spanish and become conversational before my trip to Spain next summer.",
        category: "Learning",
        peopleCount: 317
    ),

    SharedGoal(
        userImageUrl: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1720756235/avatars_collection/k0y44amiztqdalrue3mz.png",
        userName: "James W.",
        dateAdded: "1d ago",
        goalDescription: "Save $10,000 for my first home. Getting serious about budgeting and saving every month.",
        category: "Financial",
        peopleCount: 421
    ),

    SharedGoal(
        userImageUrl: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1695964845/bots/female_agent_1.jpg",
        userName: "Ava C.",
        dateAdded: "1d ago",
        goalDescription: "Get stronger and build muscle. Committing to strength training four days a week.",
        category: "Health & Fitness",
        peopleCount: 276
    ),

    SharedGoal(
        userImageUrl: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1695991791/bots/male_agent_3.jpg",
        userName: "Noah P.",
        dateAdded: "2d ago",
        goalDescription: "Transition into a career in software engineering. Studying coding and building projects every day.",
        category: "Career & Business",
        peopleCount: 163
    ),

    SharedGoal(
        userImageUrl: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1720756860/avatars_collection/riuemp9d4hoixuilh01i.png",
        userName: "Isabella L.",
        dateAdded: "2d ago",
        goalDescription: "Spend more quality time with family. Creating intentional moments together instead of letting life get too busy.",
        category: "Relationships",
        peopleCount: 92
    ),

    SharedGoal(
        userImageUrl:  "https://res.cloudinary.com/dgowl1p3x/image/upload/v1695991790/bots/male_agent_1.jpg",
        userName: "Ethan D.",
        dateAdded: "3d ago",
        goalDescription: "Complete my first triathlon. Swimming, cycling, and running my way toward a big personal milestone.",
        category: "Health & Fitness",
        peopleCount: 118
    ),

    SharedGoal(
        userImageUrl: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1720757018/avatars_collection/v8bao6rw9oyspszefnbd.png",
        userName: "Mia H.",
        dateAdded: "3d ago",
        goalDescription: "Build a consistent morning routine. Wake up earlier, meditate, exercise, and start each day with purpose.",
        category: "Personal Growth",
        peopleCount: 356
    ),

    SharedGoal(
        userImageUrl: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1720756426/avatars_collection/umchxfsfk19hwvzpdhbq.png",
        userName: "Liam S.",
        dateAdded: "4d ago",
        goalDescription: "Become financially independent by growing my investments, increasing my income, and spending more intentionally.",
        category: "Financial",
        peopleCount: 203
    )
]



