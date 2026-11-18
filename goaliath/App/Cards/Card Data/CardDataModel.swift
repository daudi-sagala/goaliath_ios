//
//  CardDataModel.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import Foundation


struct CardData: Codable {
    let cardDataId: String
    let cardDataTypeId: String
    let cardDataTypeTitle: String
    let cardDataType: CardDataType
    let title: String
    let description: String
    let imageUrl: String
    let startHour: String
    let endHour: String
}

struct CardDataType: Codable {
    let cardDataTypeId: String
    let activity: Activity?
    let formData: FormData?
    let gift: Gift?
    let suggestedMeal: SuggestedMeal?
    let message: Message?
    let post: Post?
    let task: Task?
    let userStatus: UserStatus?
    let workout: Workout?

}

//to uniquely idenity the content

