//
//  SettingsManager.swift
//  iQuiz
//
//  Created by Edward Lee on 5/13/25.
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    private enum DefaultsKeys {
        static let dataSourceURL = "dataSourceURL"
        static let autoRefreshEnabled = "autoRefreshEnabled"
        static let refreshInterval = "refreshInterval"
    }
    
    private let defaultURL = "https://tednewardsandbox.site44.com/questions.json"
    
    private let defaultRefreshInterval = 1800
    
    var dataSourceURL: String {
        get {
            return defaults.string(forKey: DefaultsKeys.dataSourceURL) ?? defaultURL
        }
        set {
            defaults.set(newValue, forKey: DefaultsKeys.dataSourceURL)
        }
    }
    
    var isAutoRefreshEnabled: Bool {
        get {
            return defaults.bool(forKey: DefaultsKeys.autoRefreshEnabled)
        }
        set {
            defaults.set(newValue, forKey: DefaultsKeys.autoRefreshEnabled)
        }
    }
    
    var refreshInterval: Int {
        get {
            return defaults.integer(forKey: DefaultsKeys.refreshInterval) != 0 ?
                   defaults.integer(forKey: DefaultsKeys.refreshInterval) :
                   defaultRefreshInterval
        }
        set {
            defaults.set(newValue, forKey: DefaultsKeys.refreshInterval)
        }
    }
    
    func resetToDefaults() {
        dataSourceURL = defaultURL
        isAutoRefreshEnabled = false
        refreshInterval = defaultRefreshInterval
    }
    
    private init() {
        if defaults.string(forKey: DefaultsKeys.dataSourceURL) == nil {
            resetToDefaults()
        }
    }
}
