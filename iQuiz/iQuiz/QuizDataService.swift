//
//  QuizDataService.swift
//  iQuiz
//
//  Created by Edward Lee on 5/20/25.
//

import Foundation
import UIKit
import SystemConfiguration

class QuizDataService {
    static let shared = QuizDataService()
    
    private init() {
        // Initialize with default quizzes if no local data exists
        if !hasLocalData() {
            saveDefaultQuizzes()
        }
    }
    
    // Path to local JSON file
    private func getLocalDataURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("quizzes.json")
    }
    
    // Check if local data exists
    func hasLocalData() -> Bool {
        return FileManager.default.fileExists(atPath: getLocalDataURL().path)
    }
    
    // Load topics from local storage
    func loadLocalQuizTopics() -> [QuizTopicData] {
        do {
            let data = try Data(contentsOf: getLocalDataURL())
            let topics = try JSONDecoder().decode([QuizTopicData].self, from: data)
            return topics
        } catch {
            print("Error loading quiz topics: \(error)")
            return []
        }
    }
    
    // Save quiz topics to local storage
    func saveQuizTopics(_ topics: [QuizTopicData]) {
        do {
            let data = try JSONEncoder().encode(topics)
            try data.write(to: getLocalDataURL())
        } catch {
            print("Error saving quiz topics: \(error)")
        }
    }
    
    // my default quizzes
    private func saveDefaultQuizzes() {
        let defaultQuizzes: [QuizTopicData] = [
            QuizTopicData(
                title: "Mathematics",
                description: "Test your math knowledge with algebra, geometry, and more",
                iconName: "function",
                questions: [
                    QuestionData(
                        text: "What is 15% of 200?",
                        options: ["25", "30", "35", "40"],
                        correctAnswerIndex: 1
                    ),
                    QuestionData(
                        text: "What is the next prime number after 7?",
                        options: ["9", "10", "11", "13"],
                        correctAnswerIndex: 2
                    ),
                    QuestionData(
                        text: "What is the value of 2^3?",
                        options: ["6", "8", "9", "12"],
                        correctAnswerIndex: 1
                    )
                ]
            ),
            QuizTopicData(
                title: "Marvel Super Heroes",
                description: "How well do you know your favorite Marvel characters?",
                iconName: "bolt.fill",
                questions: [
                    QuestionData(
                        text: "What is the name of Thor's hammer?",
                        options: ["Stormbreaker", "Gungnir", "Mjolnir", "Aegis"],
                        correctAnswerIndex: 2
                    ),
                    QuestionData(
                        text: "Which Marvel character turns green when angry?",
                        options: ["Hawkeye", "Hulk", "Wolverine", "Cyclops"],
                        correctAnswerIndex: 1
                    ),
                    QuestionData(
                        text: "Which superhero is from Wakanda?",
                        options: ["Black Panther", "Doctor Strange", "Iron Fist", "Falcon"],
                        correctAnswerIndex: 0
                    )
                ]
            ),
            QuizTopicData(
                title: "Science",
                description: "Challenge yourself with questions about physics, chemistry, and biology",
                iconName: "atom",
                questions: [
                    QuestionData(
                        text: "What gas do plants absorb from the atmosphere?",
                        options: ["Oxygen", "Carbon Dioxide", "Nitrogen", "Helium"],
                        correctAnswerIndex: 1
                    ),
                    QuestionData(
                        text: "What part of the cell contains genetic material?",
                        options: ["Cytoplasm", "Ribosome", "Nucleus", "Mitochondria"],
                        correctAnswerIndex: 2
                    ),
                    QuestionData(
                        text: "At what temperature does water boil at sea level (in Celsius)?",
                        options: ["90°C", "95°C", "100°C", "105°C"],
                        correctAnswerIndex: 2
                    )
                ]
            )
        ]
        
        saveQuizTopics(defaultQuizzes)
    }
    
    // Fetch quizzes from remote URL
    func fetchRemoteQuizzes(completion: @escaping ([QuizTopicData]?, Error?) -> Void) {
        guard let urlString = UserDefaults.standard.string(forKey: UserDefaultsKeys.quizDataURL),
              let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "QuizDataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "QuizDataService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                }
                return
            }
            
            do {
                let quizzes = try JSONDecoder().decode([QuizTopicData].self, from: data)
                DispatchQueue.main.async {
                    completion(quizzes, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
    }
    
    // Check if device is online
    func isOnline() -> Bool {
        var flags = SCNetworkReachabilityFlags()

        let isReachable = flags.contains(.reachable)
        let connectionRequired = flags.contains(.connectionRequired)
        
        return isReachable && !connectionRequired
    }
}
