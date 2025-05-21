//
//  QuizDataModels.swift
//  iQuiz
//
//  Created by Edward Lee on 5/20/25.
//

import Foundation
import UIKit

struct QuizTopicData: Codable {
    let title: String
    let description: String
    let iconName: String
    let questions: [QuestionData]
    
    // Convert from data model to view model
    func toQuizTopic() -> QuizTopic {
        return QuizTopic(
            title: title,
            description: description,
            icon: UIImage(systemName: iconName) ?? UIImage(systemName: "questionmark.circle")!
        )
    }
    
    // Get the array of questions as view model questions
    func getQuestions() -> [Question] {
        return questions.map { $0.toQuestion() }
    }
}

struct QuestionData: Codable {
    let text: String
    let options: [String]
    let correctAnswerIndex: Int
    
    // Convert from data model to view model
    func toQuestion() -> Question {
        return Question(
            text: text,
            options: options,
            correctAnswerIndex: correctAnswerIndex
        )
    }
}

// User defaults keys for settings
struct UserDefaultsKeys {
    static let quizDataURL = "quizDataURL"
    
    // Default URL for fetching quiz data
    static let defaultQuizDataURL = "https://tednewardsandbox.site44.com/questions.json"
}
