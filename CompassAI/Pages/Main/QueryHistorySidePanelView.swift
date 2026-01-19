//
//  QueryHistorySidePanelView.swift
//  CompassAI
//
//  Created by Steve on 1/17/26.
//
//

import UIKit
import CoreData

// MARK: - Side Panel Delegate Protocol
protocol QueryHistorySidePanelViewDelegate: AnyObject {
    func sidePanelDidSelectItem(_ objectID: NSManagedObjectID)
    func sidePanelDidDeleteItem(_ objectID: NSManagedObjectID, at indexPath: IndexPath)
}

class QueryAnswerCellViewModel {
    var topicName: String?
    var category: String?
    var objectID: NSManagedObjectID?
    func initFromCoreData(coreDataObject: QueryAnswerObject) {
        self.topicName = coreDataObject.topic
        self.category = coreDataObject.category
        self.objectID = coreDataObject.objectID
    }
}

// MARK: - Side Panel View
class QueryHistorySidePanelView: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let headerLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let tableView = UITableView()
    private let overlayView = UIView()
    
    // MARK: - Properties
    weak var delegate: QueryHistorySidePanelViewDelegate?
    private var leadingConstraint: NSLayoutConstraint!
    private(set) var isVisible = false
    private let panelWidth: CGFloat = 280
    
//    private var persistedQueryAnswers: [QueryAnswerObject] = []
    private var persistedQueryAnswers: [QueryAnswerCellViewModel] = []
    
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        setupOverlay()
        setupContainer()
        setupHeader()
        setupTableView()
        setupConstraints()
        setupGestures()
    }
    
    private func setupOverlay() {
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.alpha = 0
        overlayView.isHidden = true
        addSubview(overlayView)
    }
    
    private func setupContainer() {
        containerView.backgroundColor = .white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 2, height: 0)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.3
        addSubview(containerView)
    }
    
    private func setupHeader() {
        // Header label
        headerLabel.text = "Saved Answers"
        headerLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        headerLabel.textColor = .black
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerLabel)
        
        // Close button
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .black
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        containerView.addSubview(closeButton)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(QueryHistoryCellInternal.self, forCellReuseIdentifier: "QueryHistoryCellInternal")
        containerView.addSubview(tableView)
    }
    
    private func setupConstraints() {
        leadingConstraint = containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -panelWidth)
        
        NSLayoutConstraint.activate([
            // Overlay
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Container
            leadingConstraint,
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: panelWidth),
            
            // Header label
            headerLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            // Close button
            closeButton.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupGestures() {
        // Tap overlay to close
        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(closeButtonTapped))
        overlayView.addGestureRecognizer(overlayTap)
        
        // Swipe left to close
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeToClose))
        swipeLeft.direction = .left
        overlayView.addGestureRecognizer(swipeLeft)
    }
    
    private func queryAnswerArrayFromCoreData(coreDataQueryAnswers: [QueryAnswerObject]) -> [QueryAnswerCellViewModel] {
        let n = coreDataQueryAnswers.count
        var answers = [QueryAnswerCellViewModel]()
        for cd in coreDataQueryAnswers {
            let mem = QueryAnswerCellViewModel()
            mem.initFromCoreData(coreDataObject: cd)
            answers.append(mem)
        }
        return answers
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        hide()
    }
    
    @objc private func handleSwipeToClose() {
        hide()
    }
    
    // MARK: - Public Methods
    func show() {
        guard !isVisible else { return }
        
        isVisible = true
        overlayView.isHidden = false
        leadingConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.overlayView.alpha = 1
            self.layoutIfNeeded()
        }
    }
    
    func hide() {
        guard isVisible else { return }
        
        isVisible = false
        leadingConstraint.constant = -panelWidth
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.overlayView.alpha = 0
            self.layoutIfNeeded()
        } completion: { _ in
            self.overlayView.isHidden = true
        }
    }
    
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func updateData(_ coreDataQueryAnswers: [QueryAnswerObject]) {
//        self.persistedQueryAnswers = coreDataQueryAnswers
        self.persistedQueryAnswers = queryAnswerArrayFromCoreData(coreDataQueryAnswers: coreDataQueryAnswers)
        tableView.reloadData()
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    func removeItem(at index: Int) {
        guard index < persistedQueryAnswers.count else { return }
        persistedQueryAnswers.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
    }
    
    
    // MARK: - Touch Handling
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // If the side panel is not visible, pass touches through to views behind
        if !isVisible {
            return nil
        }
        
        // If visible, handle touches normally
        return super.hitTest(point, with: event)
    }
}


// MARK: - UITableViewDataSource & UITableViewDelegate
extension QueryHistorySidePanelView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return persistedQueryAnswers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QueryHistoryCellInternal", for: indexPath) as! QueryHistoryCellInternal
        
        let queryAnswer = persistedQueryAnswers[indexPath.row]
        cell.configure(with: queryAnswer)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = persistedQueryAnswers[indexPath.row]
            delegate?.sidePanelDidDeleteItem(item.objectID!, at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = persistedQueryAnswers[indexPath.row]
        delegate?.sidePanelDidSelectItem(item.objectID!)
    }
}

// MARK: - Internal Query History Cell
private class QueryHistoryCellInternal: UITableViewCell {
    private let topicLabel = UILabel()
    private let categoryLabel = UILabel()
//    private let dateLabel = UILabel()
//    private let ratingLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Topic label
        topicLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        topicLabel.textColor = .black
        topicLabel.numberOfLines = 2
        topicLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        // Category label
        categoryLabel.font = UIFont.systemFont(ofSize: 12)
        categoryLabel.textColor = .black
        categoryLabel.numberOfLines = 1
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
     
        contentView.addSubview(topicLabel)
        contentView.addSubview(categoryLabel)

        // TODO: Make this correct.
        NSLayoutConstraint.activate([
            topicLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            topicLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25),
            topicLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 20),
//            topicLabel.trailingAnchor.constraint(equalTo: ratingLabel.leadingAnchor, constant: 0),
            
            categoryLabel.topAnchor.constraint(equalTo: topicLabel.bottomAnchor, constant: 4),
            categoryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25),
            categoryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            
        ])
    }
    
    func configure(with queryAnswerCellViewModel: QueryAnswerCellViewModel) {
        if let topicName = queryAnswerCellViewModel.topicName {
            topicLabel.text = topicName
        } else {
            topicLabel.text = "Unknown Topic"
        }
        if let categoryName = queryAnswerCellViewModel.category {
            categoryLabel.text = categoryName
        }
        else {
            categoryLabel.text = ""
//            categoryLabel.text = "Unknown Category"
        }
    }
    
    func configure(withCoreData queryAnswer: QueryAnswerObject) {
        if let topicName = queryAnswer.topic {
            topicLabel.text = topicName
        } else {
            topicLabel.text = "Unknown Topic"
        }
        if let categoryName = queryAnswer.category {
            categoryLabel.text = categoryName
        }
        else {
            categoryLabel.text = ""
//            categoryLabel.text = "Unknown Category"
        }
    }
}
