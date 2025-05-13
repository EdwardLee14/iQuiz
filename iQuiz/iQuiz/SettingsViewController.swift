//
//  SettingsViewController.swift
//  iQuiz
//
//  Created by Edward Lee on 5/13/25.
//

import UIKit

protocol SettingsViewControllerDelegate: AnyObject {
    func didUpdateSettings()
    func didCheckForUpdates()
}

class SettingsViewController: UIViewController {
    
    weak var delegate: SettingsViewControllerDelegate?
    
    private let contentStackView = UIStackView()
    private let urlLabel = UILabel()
    private let urlTextField = UITextField()
    private let checkNowButton = UIButton(type: .system)
    private let autoRefreshStack = UIStackView()
    private let autoRefreshLabel = UILabel()
    private let autoRefreshSwitch = UISwitch()
    private let refreshIntervalStack = UIStackView()
    private let refreshIntervalLabel = UILabel()
    private let refreshIntervalTextField = UITextField()
    private let minutesLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Settings"
        
        setupUI()
        loadSettings()
    }
    
    private func setupUI() {
        // Content Stack View
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.alignment = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStackView)
        
        // URL Label
        urlLabel.text = "Data Source URL:"
        urlLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        contentStackView.addArrangedSubview(urlLabel)
        
        // URL Text Field
        urlTextField.borderStyle = .roundedRect
        urlTextField.placeholder = "Enter URL"
        contentStackView.addArrangedSubview(urlTextField)
        
        // Check Now Button
        checkNowButton.setTitle("Check Now", for: .normal)
        checkNowButton.backgroundColor = .systemBlue
        checkNowButton.setTitleColor(.white, for: .normal)
        checkNowButton.layer.cornerRadius = 5
        checkNowButton.addTarget(self, action: #selector(checkNowButtonTapped), for: .touchUpInside)
        contentStackView.addArrangedSubview(checkNowButton)
        
        // Auto Refresh Stack
        autoRefreshStack.axis = .horizontal
        autoRefreshStack.spacing = 10
        autoRefreshStack.alignment = .center
        
        autoRefreshLabel.text = "Auto Refresh:"
        autoRefreshLabel.font = UIFont.systemFont(ofSize: 16)
        autoRefreshStack.addArrangedSubview(autoRefreshLabel)
        
        autoRefreshSwitch.addTarget(self, action: #selector(autoRefreshSwitchChanged), for: .valueChanged)
        autoRefreshStack.addArrangedSubview(autoRefreshSwitch)
        
        contentStackView.addArrangedSubview(autoRefreshStack)
        
        // Refresh Interval Stack
        refreshIntervalStack.axis = .horizontal
        refreshIntervalStack.spacing = 10
        refreshIntervalStack.alignment = .center
        
        refreshIntervalLabel.text = "Refresh every:"
        refreshIntervalLabel.font = UIFont.systemFont(ofSize: 16)
        refreshIntervalStack.addArrangedSubview(refreshIntervalLabel)
        
        refreshIntervalTextField.borderStyle = .roundedRect
        refreshIntervalTextField.placeholder = "30"
        refreshIntervalTextField.keyboardType = .numberPad
        refreshIntervalTextField.textAlignment = .right
        refreshIntervalTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        refreshIntervalTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        refreshIntervalStack.addArrangedSubview(refreshIntervalTextField)
        
        minutesLabel.text = "minutes"
        minutesLabel.font = UIFont.systemFont(ofSize: 16)
        refreshIntervalStack.addArrangedSubview(minutesLabel)
        
        contentStackView.addArrangedSubview(refreshIntervalStack)
        
        // Buttons Stack
        let buttonsStack = UIStackView()
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 20
        buttonsStack.distribution = .fillEqually
        
        // Save Button
        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = .systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 5
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        buttonsStack.addArrangedSubview(saveButton)
        
        // Reset Button
        resetButton.setTitle("Reset", for: .normal)
        resetButton.backgroundColor = .systemRed
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.layer.cornerRadius = 5
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        buttonsStack.addArrangedSubview(resetButton)
        
        contentStackView.addArrangedSubview(buttonsStack)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            checkNowButton.heightAnchor.constraint(equalToConstant: 44),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            resetButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Set up tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func loadSettings() {
        urlTextField.text = SettingsManager.shared.dataSourceURL
        autoRefreshSwitch.isOn = SettingsManager.shared.isAutoRefreshEnabled
        
        // Convert seconds to minutes for display
        let minutes = SettingsManager.shared.refreshInterval / 60
        refreshIntervalTextField.text = String(minutes)
        
        // Update UI based on auto refresh setting
        updateRefreshIntervalVisibility()
    }
    
    @objc private func checkNowButtonTapped() {
        // Update URL if changed
        if let url = urlTextField.text, !url.isEmpty {
            SettingsManager.shared.dataSourceURL = url
        }
        
        // Show activity indicator
        let alert = UIAlertController(title: "Checking for Updates", message: "Please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true)
        
        // Fetch data
        NetworkManager.shared.fetchQuizData(from: SettingsManager.shared.dataSourceURL) { [weak self] data, error in
            // Dismiss the loading indicator on the main thread
            DispatchQueue.main.async {
                self?.dismiss(animated: true) {
                    // Show result
                    if let error = error {
                        self?.showAlert(title: "Error", message: "Failed to fetch data: \(error.localizedDescription)")
                    } else if data != nil {
                        self?.showAlert(title: "Success", message: "Data updated successfully!")
                        self?.delegate?.didCheckForUpdates()
                    }
                }
            }
        }
    }
    
    @objc private func saveButtonTapped() {
        // Save URL
        if let url = urlTextField.text, !url.isEmpty {
            SettingsManager.shared.dataSourceURL = url
        }
        
        // Save auto refresh setting
        SettingsManager.shared.isAutoRefreshEnabled = autoRefreshSwitch.isOn
        
        // Save refresh interval (convert from minutes to seconds)
        if let intervalText = refreshIntervalTextField.text, let minutes = Int(intervalText) {
            SettingsManager.shared.refreshInterval = minutes * 60
        }
        
        // Notify delegate
        delegate?.didUpdateSettings()
        
        // Show confirmation and dismiss
        showAlert(title: "Settings Saved", message: "Your settings have been saved.") { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func resetButtonTapped() {
        SettingsManager.shared.resetToDefaults()
        loadSettings()
        
        // Notify delegate
        delegate?.didUpdateSettings()
        
        showAlert(title: "Settings Reset", message: "Settings have been reset to defaults.")
    }
    
    @objc private func autoRefreshSwitchChanged() {
        updateRefreshIntervalVisibility()
    }
    
    private func updateRefreshIntervalVisibility() {
        refreshIntervalStack.isHidden = !autoRefreshSwitch.isOn
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: completion)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
