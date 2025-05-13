//  ViewController.swift
//  iQuiz
//
//  Created by Edward Lee on 5/5/25.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SettingsViewControllerDelegate {
    
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var refreshTimer: Timer?
    
    // Data sources
    private var quizTopics: [QuizTopic] = []
    private var quizQuestions: [[Question]] = []
    
    // Online status banner
    private let offlineBanner = UIView()
    private let offlineLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        setupOfflineBanner()
        setupLoadingIndicator()
        
        // Register for network status notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged(_:)),
            name: Notification.Name("NetworkStatusChanged"),
            object: nil
        )
        
        // Initial data fetch
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check network status and update UI
        updateOfflineBanner()
        
        // Set up auto refresh timer if enabled
        setupAutoRefreshTimer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        refreshTimer?.invalidate()
    }
    
    // Setup Methods
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "QuizCell")
        
        // Add pull to refresh
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupNavigationBar() {
        title = "iQuiz"
        
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    private func setupOfflineBanner() {
        offlineBanner.backgroundColor = .systemRed
        offlineBanner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(offlineBanner)
        
        offlineLabel.text = "No network connection available"
        offlineLabel.textColor = .white
        offlineLabel.textAlignment = .center
        offlineLabel.translatesAutoresizingMaskIntoConstraints = false
        offlineBanner.addSubview(offlineLabel)
        
        NSLayoutConstraint.activate([
            offlineBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            offlineBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineBanner.heightAnchor.constraint(equalToConstant: 40),
            
            offlineLabel.centerYAnchor.constraint(equalTo: offlineBanner.centerYAnchor),
            offlineLabel.leadingAnchor.constraint(equalTo: offlineBanner.leadingAnchor, constant: 10),
            offlineLabel.trailingAnchor.constraint(equalTo: offlineBanner.trailingAnchor, constant: -10)
        ])
        
        offlineBanner.isHidden = true
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupAutoRefreshTimer() {
        refreshTimer?.invalidate()
        
        if SettingsManager.shared.isAutoRefreshEnabled {
            let interval = TimeInterval(SettingsManager.shared.refreshInterval)
            refreshTimer = Timer.scheduledTimer(timeInterval: interval,
                                               target: self,
                                               selector: #selector(autoRefreshData),
                                               userInfo: nil,
                                               repeats: true)
        }
    }
    
    // Data Methods
    
    private func loadData() {
        // Check if we're online
        if !NetworkManager.shared.isNetworkAvailable {
            // If we have default data, show it
            if quizTopics.isEmpty {
                loadDefaultData()
            }
            
            // Show network error
            let alert = UIAlertController(
                title: "Network Unavailable",
                message: "Cannot connect to the internet. Showing local data.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            
            return
        }
        
        // Show loading indicator
        loadingIndicator.startAnimating()
        
        // Fetch data from API
        NetworkManager.shared.fetchQuizData(from: SettingsManager.shared.dataSourceURL) { [weak self] quizData, error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.refreshControl.endRefreshing()
                
                if let error = error {
                    print("Error fetching quiz data: \(error.localizedDescription)")
                    
                    // Show error and load default data if we don't have any data yet
                    self?.showAlert(title: "Error", message: "Failed to load quiz data: \(error.localizedDescription)")
                    
                    if self?.quizTopics.isEmpty ?? true {
                        self?.loadDefaultData()
                    }
                    
                    return
                }
                
                guard let quizData = quizData else {
                    print("No quiz data returned")
                    return
                }
                
                // Convert API data to app model
                let convertedData = NetworkManager.shared.convertToAppModel(from: quizData)
                
                // Split into topics and questions
                self?.quizTopics = convertedData.map { $0.topic }
                self?.quizQuestions = convertedData.map { $0.questions }
                
                // Reload table view
                self?.tableView.reloadData()
            }
        }
    }
    
    private func loadDefaultData() {
        // Default quiz topics
        quizTopics = [
            QuizTopic(
                title: "Mathematics",
                description: "Test your math knowledge with algebra, geometry, and more",
                icon: UIImage(systemName: "function") ?? UIImage(systemName: "questionmark.circle")!
            ),
            QuizTopic(
                title: "Marvel Super Heroes",
                description: "How well do you know your favorite Marvel characters?",
                icon: UIImage(systemName: "bolt.fill") ?? UIImage(systemName: "questionmark.circle")!
            ),
            QuizTopic(
                title: "Science",
                description: "Challenge yourself with questions about physics, chemistry, and biology",
                icon: UIImage(systemName: "atom") ?? UIImage(systemName: "questionmark.circle")!
            )
        ]
        
        // Default questions for each topic
        quizQuestions = [
            // Math questions
            [
                Question(
                    text: "What is 15% of 200?",
                    options: ["25", "30", "35", "40"],
                    correctAnswerIndex: 1
                ),
                Question(
                    text: "What is the next prime number after 7?",
                    options: ["9", "10", "11", "13"],
                    correctAnswerIndex: 2
                ),
                Question(
                    text: "What is the value of 2^3?",
                    options: ["6", "8", "9", "12"],
                    correctAnswerIndex: 1
                )
            ],
            
            // Marvel questions
            [
                Question(
                    text: "What is the name of Thor's hammer?",
                    options: ["Stormbreaker", "Gungnir", "Mjolnir", "Aegis"],
                    correctAnswerIndex: 2
                ),
                Question(
                    text: "Which Marvel character turns green when angry?",
                    options: ["Hawkeye", "Hulk", "Wolverine", "Cyclops"],
                    correctAnswerIndex: 1
                ),
                Question(
                    text: "Which superhero is from Wakanda?",
                    options: ["Black Panther", "Doctor Strange", "Iron Fist", "Falcon"],
                    correctAnswerIndex: 0
                )
            ],
            
            // Science questions
            [
                Question(
                    text: "What gas do plants absorb from the atmosphere?",
                    options: ["Oxygen", "Carbon Dioxide", "Nitrogen", "Helium"],
                    correctAnswerIndex: 1
                ),
                Question(
                    text: "What part of the cell contains genetic material?",
                    options: ["Cytoplasm", "Ribosome", "Nucleus", "Mitochondria"],
                    correctAnswerIndex: 2
                ),
                Question(
                    text: "At what temperature does water boil at sea level (in Celsius)?",
                    options: ["90°C", "95°C", "100°C", "105°C"],
                    correctAnswerIndex: 2
                )
            ]
        ]
        
        tableView.reloadData()
    }
    
    @objc private func refreshData() {
        loadData()
    }
    
    @objc private func autoRefreshData() {
        // Only auto refresh if online
        if NetworkManager.shared.isNetworkAvailable {
            loadData()
        }
    }
    
    // Network Status
    
    @objc private func networkStatusChanged(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.updateOfflineBanner()
        }
    }
    
    private func updateOfflineBanner() {
        let isOffline = !NetworkManager.shared.isNetworkAvailable
        
        // Only animate if visibility is changing
        if offlineBanner.isHidden == isOffline {
            if isOffline {
                // Show banner
                self.offlineBanner.isHidden = false
                self.offlineBanner.alpha = 0
                
                UIView.animate(withDuration: 0.3) {
                    self.offlineBanner.alpha = 1
                }
            } else {
                // Hide banner
                UIView.animate(withDuration: 0.3, animations: {
                    self.offlineBanner.alpha = 0
                }) { _ in
                    self.offlineBanner.isHidden = true
                }
            }
        }
        
        // Adjust table view insets if banner is visible
        let topInset: CGFloat = isOffline ? 40 : 0
        tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    }
    
    // Actions
    
    @objc private func showSettings() {
        let settingsVC = SettingsViewController()
        settingsVC.delegate = self
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // SettingsViewControllerDelegate
    
    func didUpdateSettings() {
        setupAutoRefreshTimer()
    }
    
    func didCheckForUpdates() {
        loadData()
    }
    
    // UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quizTopics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "QuizCell")
        
        let topic = quizTopics[indexPath.row]
        
        cell.imageView?.image = topic.icon
        cell.imageView?.contentMode = .scaleAspectFit
        
        let title = topic.title
        cell.textLabel?.text = title.count > 30 ? String(title.prefix(30)) : title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        cell.detailTextLabel?.text = topic.description
        cell.detailTextLabel?.textColor = .darkGray
        
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    // UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Make sure we have questions for this topic
        guard indexPath.row < quizQuestions.count else {
            showAlert(title: "Error", message: "No questions available for this topic.")
            return
        }
        
        // Start the quiz with the selected topic
        startQuiz(topicIndex: indexPath.row)
    }
    
    private func startQuiz(topicIndex: Int) {
        let topic = quizTopics[topicIndex]
        let questions = quizQuestions[topicIndex]
        
        let questionVC = QuestionViewController()
        questionVC.topic = topic
        questionVC.questions = questions
        
        navigationController?.pushViewController(questionVC, animated: true)
    }
}

// Question View Controller
class QuestionViewController: UIViewController {
    var topic: QuizTopic!
    var questions: [Question] = []
    var currentQuestionIndex = 0
    var userAnswers: [Int?] = []
    private var selectedAnswerIndex: Int?
    
    private let questionLabel = UILabel()
    private let optionsStackView = UIStackView()
    private let submitButton = UIButton(type: .system)
    private var optionButtons: [UIButton] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = topic.title
        
        // Initialize user answers array if it's empty
        if userAnswers.isEmpty {
            userAnswers = Array(repeating: nil, count: questions.count)
        }
        
        setupUI()
        displayQuestion()
    }
    
    private func setupUI() {
        // Question Label
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 0
        questionLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        view.addSubview(questionLabel)
        
        // Options Stack View
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.axis = .vertical
        optionsStackView.spacing = 10
        optionsStackView.distribution = .fillEqually
        view.addSubview(optionsStackView)
        
        // Submit Button
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle("Submit", for: .normal)
        submitButton.backgroundColor = .systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 5
        submitButton.isEnabled = false
        submitButton.addTarget(self, action: #selector(submitAnswer), for: .touchUpInside)
        view.addSubview(submitButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            questionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            optionsStackView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 30),
            optionsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            optionsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            submitButton.topAnchor.constraint(equalTo: optionsStackView.bottomAnchor, constant: 30),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 200),
            submitButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func displayQuestion() {
        let question = questions[currentQuestionIndex]
        questionLabel.text = question.text
        
        // Clear previous options
        optionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        optionButtons.removeAll()
        
        // Add option buttons
        for (index, option) in question.options.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.backgroundColor = .systemGray6
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = 5
            button.tag = index
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
            button.addTarget(self, action: #selector(optionSelected(_:)), for: .touchUpInside)
            
            optionsStackView.addArrangedSubview(button)
            optionButtons.append(button)
        }
        
        // Check if this question has a previously selected answer
        if let previousAnswer = userAnswers[currentQuestionIndex], previousAnswer < optionButtons.count {
            optionSelected(optionButtons[previousAnswer])
        } else {
            // Reset selected answer
            selectedAnswerIndex = nil
            submitButton.isEnabled = false
        }
    }
    
    @objc private func optionSelected(_ sender: UIButton) {
        // Reset all buttons
        optionButtons.forEach { button in
            button.backgroundColor = .systemGray6
            button.setTitleColor(.black, for: .normal)
        }
        
        // Highlight selected button
        sender.backgroundColor = .systemBlue
        sender.setTitleColor(.white, for: .normal)
        
        selectedAnswerIndex = sender.tag
        submitButton.isEnabled = true
    }
    
    @objc private func submitAnswer() {
        guard let selectedIndex = selectedAnswerIndex else { return }
        
        // Save user's answer
        userAnswers[currentQuestionIndex] = selectedIndex
        
        // Show answer screen
        let answerVC = AnswerViewController()
        answerVC.topic = topic
        answerVC.questions = questions
        answerVC.currentQuestionIndex = currentQuestionIndex
        answerVC.userAnswers = userAnswers
        answerVC.selectedAnswerIndex = selectedIndex
        
        navigationController?.pushViewController(answerVC, animated: true)
    }
}

// Answer View Controller
class AnswerViewController: UIViewController {
    var topic: QuizTopic!
    var questions: [Question] = []
    var currentQuestionIndex = 0
    var userAnswers: [Int?] = []
    var selectedAnswerIndex: Int!
    
    private let questionLabel = UILabel()
    private let resultLabel = UILabel()
    private let correctAnswerLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = topic.title
        
        setupUI()
        showResult()
    }
    
    private func setupUI() {
        // Question Label
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 0
        questionLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        view.addSubview(questionLabel)
        
        // Result Label
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.textAlignment = .center
        resultLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        view.addSubview(resultLabel)
        
        // Correct Answer Label
        correctAnswerLabel.translatesAutoresizingMaskIntoConstraints = false
        correctAnswerLabel.textAlignment = .center
        correctAnswerLabel.numberOfLines = 0
        view.addSubview(correctAnswerLabel)
        
        // Next Button
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.setTitle("Next", for: .normal)
        nextButton.backgroundColor = .systemBlue
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 5
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        view.addSubview(nextButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            questionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            resultLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 30),
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            correctAnswerLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            correctAnswerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            correctAnswerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            nextButton.topAnchor.constraint(equalTo: correctAnswerLabel.bottomAnchor, constant: 40),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 200),
            nextButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func showResult() {
        let question = questions[currentQuestionIndex]
        
        // Show question
        questionLabel.text = question.text
        
        // Check if answer is correct
        let isCorrect = selectedAnswerIndex == question.correctAnswerIndex
        
        // Show result
        resultLabel.text = isCorrect ? "Correct!" : "Wrong!"
        resultLabel.textColor = isCorrect ? .systemGreen : .systemRed
        
        // Show correct answer
        correctAnswerLabel.text = "The correct answer is: \(question.options[question.correctAnswerIndex])"
    }
    
    @objc private func nextButtonTapped() {
        if currentQuestionIndex < questions.count - 1 {
            // Go to next question
            let questionVC = QuestionViewController()
            questionVC.topic = topic
            questionVC.questions = questions
            questionVC.currentQuestionIndex = currentQuestionIndex + 1
            questionVC.userAnswers = userAnswers
            
            navigationController?.pushViewController(questionVC, animated: true)
        } else {
            // Quiz finished - all questions have been answered
            let finishedVC = FinishedViewController()
            finishedVC.topic = topic
            finishedVC.questions = questions
            finishedVC.userAnswers = userAnswers
            
            navigationController?.pushViewController(finishedVC, animated: true)
        }
    }
}

// Finished View Controller
class FinishedViewController: UIViewController {
    var topic: QuizTopic!
    var questions: [Question] = []
    var userAnswers: [Int?] = []
    
    private let titleLabel = UILabel()
    private let scoreLabel = UILabel()
    private let backButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Quiz Complete"
        
        setupUI()
        showResults()
    }
    
    private func setupUI() {
        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        view.addSubview(titleLabel)
        
        // Score Label
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.textAlignment = .center
        scoreLabel.font = UIFont.systemFont(ofSize: 18)
        view.addSubview(scoreLabel)
        
        // Back Button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Back to Topics", for: .normal)
        backButton.backgroundColor = .systemBlue
        backButton.setTitleColor(.white, for: .normal)
        backButton.layer.cornerRadius = 5
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            scoreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            backButton.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 40),
            backButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 200),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func showResults() {
        // Calculate score
        var correctCount = 0
        
        for i in 0..<questions.count {
            if let userAnswer = userAnswers[i], userAnswer == questions[i].correctAnswerIndex {
                correctCount += 1
            }
        }
        
        // For debugging
        print("User answers at finish: \(userAnswers)")
        print("Questions count: \(questions.count)")
        print("Correct count: \(correctCount)")
        
        // Set title based on performance
        let percentage = Double(correctCount) / Double(questions.count)
        
        if percentage == 1.0 {
            titleLabel.text = "Perfect!"
        } else if percentage >= 0.7 {
            titleLabel.text = "Great Job!"
        } else if percentage >= 0.5 {
            titleLabel.text = "Good Work!"
        } else {
            titleLabel.text = "Keep Practicing!"
        }
        
        // Set score text
        scoreLabel.text = "You got \(correctCount) of \(questions.count) questions correct"
    }
    
    @objc private func backButtonTapped() {
        // Go back to main screen
        navigationController?.popToRootViewController(animated: true)
    }
}
