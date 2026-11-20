//
//  Meal.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import Foundation

// MARK: - Model
struct SuggestedMeal: Codable, Identifiable {
    // V4 canonical media arrays; optional for backwards-compatible decoding.
    var image_urls: [String]? = nil
    var video_urls: [String]? = nil
    var gif_urls: [String]? = nil

    let id: UUID
    let suggestedMealId: String
    let title: String
    let imageUrl: String?
    let estimatedTime: Int // in minutrs
    let user: User
    let meals: [Meal]
    let mealUserData: MealUserData
    let createdAt: String
    let copyStatus: CopyStatus
    let priceRange: String
    
    struct User: Codable {
        let userId: String
        let name: String
        let location: String
        let avatarURL: String
    }
    
    struct Meal: Codable {
    // V4 canonical media arrays; optional for backwards-compatible decoding.
    var image_urls: [String]? = nil
    var video_urls: [String]? = nil
    var gif_urls: [String]? = nil

        let mealId: String
        let title: String
        let imageURL: String?
        let estimatedTime: Int // in minutes
        let priceRange: String?
        let recipes: [Recipe]?
        let ingredients: [Ingredient]?
        let sources: [Source]?
        
        struct Recipe: Codable {
            let recipeId: String
            let name: String
            let description: String
            let ingredients: [Ingredient]
            let instructions: [String]
            let prepTime: Int // in minutes
            let cookTime: Int // in minutes
            let servings: Int
            let difficulty: String
            let cuisine: String
            let tags: [String]
            let rating: String
            let imageUrls: [String]
            let videoUrls: [String]
            let webUrl: String
            let recipeNutrition: RecipeNutrition
            let createdAt: String
            let lastMade: LastMade
            let recipeCreator: RecipeCreator
        }
        
        struct RecipeNutrition: Codable {
            var calories: Int
            var protein: Int // in grams
            var carbs: Int // in grams
            var fat: Int // in grams
            var sugar: Int // in grams
            var sodium: Int // in milligrams
            var fiber: Int // in grams
        }
        
        struct RecipeCreator: Codable {
            let userId: String
            let name: String
            let location: String
            let userImageUrl: String
            let userDescription: String
            let conversationId: String
            let onlineStatus: String
        }
        
        struct LastMade: Codable {
            let userId: String
            let name: String
            let location: String
            let userImageUrl: String
            let userDescription: String
            let conversationId: String
            let onlineStatus: String
            let madeAt: String
        }
        
        struct Ingredient: Codable, Identifiable {
            let id: UUID
            let ingredientId: String
            let name: String
            let quantity: Double
            let units: String
            let isEssential: Bool
        }
        
        struct Source: Codable {
         
            let name: String
            let logoURL: String
            let address: String
            let distance: String
            let driveTime: String
            let isOpen: Bool
            let type: SourceType
            let website: String
            let latitude: Double
            let longitude: Double
            let phone: String
            enum SourceType: String, Codable, CaseIterable {
                case store = "store"
                case restaurant = "restaurant"
                case homeMade = "homeMade"
            }
        }
        
    }
    
    
    struct MealUserData: Codable {
        let copyCount: Int
        let userAvatars: [String] // URLs of users who have this meal in their history
    }
    
    struct CopyStatus: Codable {
        let status: String //Copied/Modified
        let timestamp: String
    }
    
}
