//
//  NetworkManager.swift
//  iQuiz
//
//  Created by Edward Lee on 5/13/25.
//

import UIKit
import Network

class NetworkManager {
    static let shared = NetworkManager()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var isNetworkAvailable = false
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkAvailable = path.status == .satisfied
            
            // Post notification about network status change
            NotificationCenter.default.post(
                name: Notification.Name("NetworkStatusChanged"),
                object: nil,
                userInfo: ["isAvailable": path.status == .satisfied]
            )
        }
        
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    func fetchQuizData(from urlString: String, completion: @escaping ([QuizData]?, Error?) -> Void) {
        guard isNetworkAvailable else {
            completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No network connection available"]))
            return
        }
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "NetworkManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(nil, NSError(domain: "NetworkManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"]))
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "NetworkManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                let quizData = try JSONDecoder().decode([QuizData].self, from: data)
                completion(quizData, nil)
            } catch {
                // Try to figure out what went wrong and print useful debug info
                print("JSON Decoding Error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Received JSON: \(jsonString.prefix(500))...")
                }
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    func convertToAppModel(from apiData: [QuizData]) -> [(topic: QuizTopic, questions: [Question])] {
        return apiData.map { quizData in
            // Create topic
            let topic = QuizTopic(
                title: quizData.title,
                description: quizData.desc,
                icon: self.iconForTopic(quizData.title)
            )
            
            // Create questions
            let questions = quizData.questions.map { apiQuestion in
                // Find the index of the correct answer
                let correctAnswerIndex = Int(apiQuestion.answer)! - 1
                
                return Question(
                    text: apiQuestion.text,
                    options: apiQuestion.answers,
                    correctAnswerIndex: correctAnswerIndex
                )
            }
            
            return (topic, questions)
        }
    }
    
    private func iconForTopic(_ topicName: String) -> UIImage {
        let lowercasedName = topicName.lowercased()
        
        if lowercasedName.contains("math") || lowercasedName.contains("science") {
            return UIImage(systemName: "function") ?? UIImage(systemName: "questionmark.circle")!
        } else if lowercasedName.contains("marvel") || lowercasedName.contains("hero") || lowercasedName.contains("comic") {
            return UIImage(systemName: "bolt.fill") ?? UIImage(systemName: "questionmark.circle")!
        } else if lowercasedName.contains("science") || lowercasedName.contains("physics") || lowercasedName.contains("chemistry") {
            return UIImage(systemName: "atom") ?? UIImage(systemName: "questionmark.circle")!
        } else if lowercasedName.contains("history") || lowercasedName.contains("world") {
            return UIImage(systemName: "book.fill") ?? UIImage(systemName: "questionmark.circle")!
        } else if lowercasedName.contains("movie") || lowercasedName.contains("film") || lowercasedName.contains("tv") {
            return UIImage(systemName: "tv.fill") ?? UIImage(systemName: "questionmark.circle")!
        } else if lowercasedName.contains("music") || lowercasedName.contains("song") {
            return UIImage(systemName: "music.note") ?? UIImage(systemName: "questionmark.circle")!
        } else if lowercasedName.contains("sport") || lowercasedName.contains("game") {
            return UIImage(systemName: "sportscourt.fill") ?? UIImage(systemName: "questionmark.circle")!
        } else {
            return UIImage(systemName: "questionmark.circle")!
        }
    }
}
