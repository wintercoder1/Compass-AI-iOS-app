//
//  CompanySuggestionDropdownView.swift
//  CompassAI
//
//  Created by Steve on 1/18/26.
//

import UIKit

// MARK: - Company Suggestion Dropdown Delegate
protocol CompanySuggestionDropdownDelegate: AnyObject {
    func companySuggestionDidSelect(_ company: String)
}

// MARK: - Company Suggestion Dropdown View
class CompanySuggestionDropdownView: UIView {
    
    // MARK: - UI Components
    private let dropdownContainer = UIView()
    private let tableView = UITableView()
    
    // MARK: - Properties
    weak var delegate: CompanySuggestionDropdownDelegate?
    private var suggestions: [String] = []
    private var dropdownHeightConstraint: NSLayoutConstraint!
    private let rowHeight: CGFloat = 50
    private let maxVisibleRows: CGFloat = 6
    private(set) var isVisible = false
    
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
        // Container styling - matches the website look
        dropdownContainer.backgroundColor = .white
        dropdownContainer.layer.cornerRadius = 12
        dropdownContainer.layer.borderWidth = 1
        dropdownContainer.layer.borderColor = UIColor.systemGray4.cgColor
        dropdownContainer.layer.shadowColor = UIColor.black.cgColor
        dropdownContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        dropdownContainer.layer.shadowRadius = 12
        dropdownContainer.layer.shadowOpacity = 0.12
        dropdownContainer.clipsToBounds = false
        dropdownContainer.translatesAutoresizingMaskIntoConstraints = false
        dropdownContainer.isHidden = true
        addSubview(dropdownContainer)
        
        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.systemGray5
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.layer.cornerRadius = 12
        tableView.clipsToBounds = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(CompanySuggestionCell.self, forCellReuseIdentifier: "CompanySuggestionCell")
        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = true
        tableView.bounces = true
        dropdownContainer.addSubview(tableView)
        
        dropdownHeightConstraint = dropdownContainer.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            dropdownContainer.topAnchor.constraint(equalTo: topAnchor),
            dropdownContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            dropdownContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            dropdownHeightConstraint,
            
            tableView.topAnchor.constraint(equalTo: dropdownContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: dropdownContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: dropdownContainer.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: dropdownContainer.bottomAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func updateSuggestions(_ suggestions: [String]) {
        self.suggestions = suggestions
        tableView.reloadData()
        updateDropdownHeight()
    }
    
    func show() {
        guard !suggestions.isEmpty else {
            hide()
            return
        }
        
        isVisible = true
        dropdownContainer.isHidden = false
        dropdownContainer.alpha = 0
        dropdownContainer.transform = CGAffineTransform(translationX: 0, y: -8)
        
        updateDropdownHeight()
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.dropdownContainer.alpha = 1
            self.dropdownContainer.transform = .identity
        }
    }
    
    func hide() {
        guard isVisible else { return }
        
        isVisible = false
        
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn) {
            self.dropdownContainer.alpha = 0
            self.dropdownContainer.transform = CGAffineTransform(translationX: 0, y: -8)
        } completion: { _ in
            self.dropdownContainer.isHidden = true
            self.dropdownContainer.transform = .identity
        }
    }
    
    private func updateDropdownHeight() {
        let calculatedHeight = min(CGFloat(suggestions.count) * rowHeight, maxVisibleRows * rowHeight)
        dropdownHeightConstraint.constant = calculatedHeight
        
        // Enable scrolling only if we have more items than visible rows
        tableView.isScrollEnabled = CGFloat(suggestions.count) > maxVisibleRows
    }
    
    // MARK: - Hit Testing
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !dropdownContainer.isHidden {
            let containerPoint = convert(point, to: dropdownContainer)
            if dropdownContainer.bounds.contains(containerPoint) {
                return tableView.hitTest(convert(point, to: tableView), with: event)
            }
        }
        return nil
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if !dropdownContainer.isHidden {
            return dropdownContainer.frame.contains(point)
        }
        return false
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension CompanySuggestionDropdownView: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompanySuggestionCell", for: indexPath) as! CompanySuggestionCell
        cell.configure(with: suggestions[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedCompany = suggestions[indexPath.row]
        delegate?.companySuggestionDidSelect(selectedCompany)
        hide()
    }
}

// MARK: - Company Suggestion Cell
class CompanySuggestionCell: UITableViewCell {
    
    private let companyNameLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .white
        selectionStyle = .none
        
        // Company name label - centered like the website
        companyNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        companyNameLabel.textColor = UIColor.darkGray
        companyNameLabel.textAlignment = .center
        companyNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(companyNameLabel)
        
        NSLayoutConstraint.activate([
            companyNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            companyNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            companyNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with companyName: String) {
        companyNameLabel.text = companyName
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            backgroundColor = UIColor.systemGray6
        } else {
            backgroundColor = .white
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            backgroundColor = UIColor.systemGray6
        } else {
            backgroundColor = .white
        }
    }
}
