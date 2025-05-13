//
//  Model.swift
//  iQuiz
//
//  Created by Edward Lee on 5/13/25.
//
import UIKit


struct QuizTopic {
    let title: String
    let description: String
    let icon: UIImage
}

struct Question {
    let text: String
    let options: [String]
    let correctAnswerIndex: Int
}

struct QuizData: Codable {
    let title: String
    let desc: String
    let questions: [QuizQuestion]
}

struct QuizQuestion: Codable {
    let text: String
    let answer: String
    let answers: [String]
}
