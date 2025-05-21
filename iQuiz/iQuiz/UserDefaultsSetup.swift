//
//  UserDefaultsSetup.swift
//  iQuiz
//
//  Created by Edward Lee on 5/20/25.
//

import Foundation

class UserDefaultsSetup {
    static func setupDefaults() {
        // Register default settings
        let defaults: [String: Any] = [
            UserDefaultsKeys.quizDataURL: UserDefaultsKeys.defaultQuizDataURL
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
}
