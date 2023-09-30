//
//  ViewController.swift
//  TodoList
//
//  Created by Семен Выдрин on 30.09.2023.
//

import UIKit
import RealmSwift

final class TaskListViewController: UITableViewController {
    private let cellID = "taskCell"
    
    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl()
        let items = ["Date", "A-z"]
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(
            self,
            action: #selector(sortingList),
            for: .valueChanged
        )
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    private var taskLists: Results<TaskList>!
    private var storageManager = StorageManager.shared
    
    // MARK: - View Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        view.addSubview(segmentedControl)
        setConstraints()
        
        taskLists = storageManager.fetchData(TaskList.self)
        
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskLists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        var content = cell.defaultContentConfiguration()
        let taskLists = taskLists[indexPath.row]
        content.text = taskLists.title
        content.secondaryText = taskLists.tasks.count.formatted()
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let taskList = taskLists[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] _, _, _ in
            storageManager.delete(taskList)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] _, _, isDone in
            showAlert(with: taskList) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let doneAction = UIContextualAction(style: .normal, title: "Done") { [unowned self] _, _, isDone in
            storageManager.done(taskList)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = .green
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction, doneAction])
    }
    
   
    // MARK: - Private methods
    @objc private func addNewTask() {
        showAlert()
    }
    
    @objc private func sortingList(_ sender: UISegmentedControl) {
        
    }
}

// MARK: - AlertController
private extension TaskListViewController {
    func showAlert(with taskList: TaskList? = nil, completion: (() -> Void)? = nil) {
        let alertBuilder = AlertControllerBuilder(
            title: taskList != nil ? "Edit List" : "New List",
            message: "Please set title for new task list"
        )
        
        alertBuilder
            .setTextField(withPlaceholder: "List title", andText: taskList?.title)
            .addAction(title: taskList != nil ? "Update List" : "Save List", style: .default) { [weak self] newValue, _ in
                if let taskList, let completion {
                    self?.storageManager.edit(taskList, newValue: newValue)
                    completion()
                    return
                }
                self?.save(taskList: newValue)
            }
            .addAction(title: "Cancel", style: .destructive)
        
        let alertController = alertBuilder.build()
        present(alertController, animated: true)
    }
    
    func save(taskList: String) {
        storageManager.save(taskList) { taskList in
            let rowIndex = IndexPath(row: taskLists.index(of: taskList) ?? 0, section: 0)
            tableView.insertRows(at: [rowIndex], with: .automatic)
        }
    }
}

// MARK: - Setup UI
private extension TaskListViewController {
    func setupView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        view.backgroundColor = .white
    }
    
    func setupNavigationBar() {
        title = "Task list"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(getter: editButtonItem)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
    }
    
    func setConstraints() {
    }
}

