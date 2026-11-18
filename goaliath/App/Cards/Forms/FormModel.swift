//
//  FormData.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import Foundation


// MARK: - Form Data
struct FormData: Codable, Identifiable {
    let formDataId: String
    let title: String
    var subtitle: String?
    var description: String?
    var imageURL: String?

    var items: [FormItem]

    var submitTitle: String = "Continue"
    var allowSkip: Bool = false

    var id: String { formDataId }
}

// MARK: - Form Item

struct FormItem: Codable, Identifiable {
    let itemId: String
    let type: FormItemType

    var title: String
    var subtitle: String?
    var placeholder: String?

    var imageURL: String?
    var imageAspectRatio: Double?

    var isRequired: Bool = false
    var isEnabled: Bool = true

    var defaultValue: String?
    var options: [FormOption]?

    var validation: FormValidation?

    var id: String { itemId }
}

// MARK: - Form Item Types

enum FormItemType: String, Codable {
    case text
    case multiline
    case number
    case email
    case phone
    case date
    case time

    case singleSelect
    case multiSelect
    case dropdown

    case toggle
    case slider

    case imageSelect
    case imageMultiSelect

    case section
    case info
}

// MARK: - Form Options

struct FormOption: Codable, Identifiable {
    let optionId: String
    let title: String

    var subtitle: String?
    var icon: String?
    var imageURL: String?

    var value: String

    var id: String { optionId }
}

// MARK: - Validation

struct FormValidation: Codable {
    var minLength: Int?
    var maxLength: Int?
    var minimum: Double?
    var maximum: Double?
    var regex: String?
    var errorMessage: String?
}

// MARK: - Form Response

struct FormResponse: Codable {
    let formDataId: String
    var answers: [String: String]
}

