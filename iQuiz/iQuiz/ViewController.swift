//
//  ViewController.swift
//  iQuiz
//
//  Created by Edward Lee on 5/5/25.
//

import UIKit

struct QuizTopic {
    let title: String
    let description: String
    let icon: UIImage
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView()
    
    private let quizTopics = [
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "QuizCell")
    }
    
    private func setupNavigationBar() {
        title = "iQuiz"
        
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(showSettingsAlert)
        )
        
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    @objc private func showSettingsAlert() {
        let alertController = UIAlertController(
            title: "Settings",
            message: "Settings go here",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(
            title: "OK",
            style: .default,
            handler: nil
        )
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        print("Selected quiz: \(quizTopics[indexPath.row].title)")
    }
}
