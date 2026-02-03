//
//  CategorySelectorView.swift
//  CompassAI
//
//  Created by Steve on 1/17/26.
//

import UIKit

// MARK: - Category Selector Delegate
protocol CategorySelectorViewDelegate: AnyObject {
    func categorySelectorDidSelectCategory(_ category: CurrentSearchCategory)
    func categorySelectorWillShowDropdown()
}

// MARK: - Category Selector View
class CategorySelectorView: UIView {
    
    // MARK: - UI Components
    private let containerButton = UIButton(type: .system)
    private let categoryLabel = UILabel()
    private let chevronImageView = UIImageView()
    private let dropdownTableView = UITableView()
    private let dropdownContainer = UIView()
    
    // MARK: - Properties
    weak var delegate: CategorySelectorViewDelegate?
    private var isDropdownVisible = false
    private let categories = CurrentSearchCategory.allCases
    private var dropdownHeightConstraint: NSLayoutConstraint!
    private let rowHeight: CGFloat = 48
    private let maxVisibleRows: CGFloat = 5
    
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
        setupContainerButton()
        setupDropdown()
        updateCategoryDisplay()
    }
    
    private func setupContainerButton() {
        // Container button styling
        containerButton.backgroundColor = .white
        containerButton.layer.cornerRadius = 10
        containerButton.layer.borderWidth = 1
        containerButton.layer.borderColor = UIColor.systemGray4.cgColor
        containerButton.layer.shadowColor = UIColor.black.cgColor
        containerButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerButton.layer.shadowRadius = 4
        containerButton.layer.shadowOpacity = 0.08
        containerButton.translatesAutoresizingMaskIntoConstraints = false
        containerButton.addTarget(self, action: #selector(containerButtonTapped), for: .touchUpInside)
        addSubview(containerButton)
        
        // Category label
        categoryLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        categoryLabel.textColor = .black
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        containerButton.addSubview(categoryLabel)
        
        // Chevron image
        chevronImageView.image = UIImage(systemName: "chevron.down")
        chevronImageView.tintColor = .systemGray
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        containerButton.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            containerButton.topAnchor.constraint(equalTo: topAnchor),
            containerButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerButton.heightAnchor.constraint(equalToConstant: 44),
            
            categoryLabel.leadingAnchor.constraint(equalTo: containerButton.leadingAnchor, constant: 14),
            categoryLabel.centerYAnchor.constraint(equalTo: containerButton.centerYAnchor),
            categoryLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            
            chevronImageView.trailingAnchor.constraint(equalTo: containerButton.trailingAnchor, constant: -14),
            chevronImageView.centerYAnchor.constraint(equalTo: containerButton.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 14),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    private func setupDropdown() {
        // Dropdown container
        dropdownContainer.backgroundColor = .white
        dropdownContainer.layer.cornerRadius = 10
        dropdownContainer.layer.borderWidth = 1
        dropdownContainer.layer.borderColor = UIColor.systemGray4.cgColor
        dropdownContainer.layer.shadowColor = UIColor.black.cgColor
        dropdownContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        dropdownContainer.layer.shadowRadius = 8
        dropdownContainer.layer.shadowOpacity = 0.15
        dropdownContainer.clipsToBounds = false
        dropdownContainer.translatesAutoresizingMaskIntoConstraints = false
        dropdownContainer.isHidden = true
        addSubview(dropdownContainer)
        
        // Dropdown table view
        dropdownTableView.delegate = self
        dropdownTableView.dataSource = self
        dropdownTableView.backgroundColor = .white
        dropdownTableView.separatorStyle = .singleLine
        dropdownTableView.separatorInset = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        dropdownTableView.layer.cornerRadius = 10
        dropdownTableView.clipsToBounds = true
        dropdownTableView.translatesAutoresizingMaskIntoConstraints = false
        dropdownTableView.register(CategoryDropdownCell.self, forCellReuseIdentifier: "CategoryDropdownCell")
        dropdownTableView.isScrollEnabled = true
        dropdownTableView.showsVerticalScrollIndicator = true
        dropdownContainer.addSubview(dropdownTableView)
        
        let dropdownHeight = min(CGFloat(categories.count) * rowHeight, maxVisibleRows * rowHeight)
        dropdownHeightConstraint = dropdownContainer.heightAnchor.constraint(equalToConstant: dropdownHeight)
        
        NSLayoutConstraint.activate([
            dropdownContainer.topAnchor.constraint(equalTo: containerButton.bottomAnchor, constant: 4),
            dropdownContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            dropdownContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            dropdownHeightConstraint,
            
            dropdownTableView.topAnchor.constraint(equalTo: dropdownContainer.topAnchor),
            dropdownTableView.leadingAnchor.constraint(equalTo: dropdownContainer.leadingAnchor),
            dropdownTableView.trailingAnchor.constraint(equalTo: dropdownContainer.trailingAnchor),
            dropdownTableView.bottomAnchor.constraint(equalTo: dropdownContainer.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func containerButtonTapped() {
        toggleDropdown()
    }
    
    // MARK: - Public Methods
    func toggleDropdown() {
        if isDropdownVisible {
            hideDropdown()
        } else {
            showDropdown()
        }
    }
    
    func showDropdown() {
        guard !isDropdownVisible else { return }
        
        isDropdownVisible = true
        dropdownContainer.isHidden = false
        dropdownContainer.alpha = 0
        dropdownContainer.transform = CGAffineTransform(scaleX: 0.95, y: 0.95).translatedBy(x: 0, y: -10)
        
        // Rotate chevron
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.chevronImageView.transform = CGAffineTransform(rotationAngle: .pi)
            self.dropdownContainer.alpha = 1
            self.dropdownContainer.transform = .identity
        }
        
        // Scroll to selected category
        if let selectedIndex = categories.firstIndex(of: CurrentConfiguration.shared.currentCategory) {
            dropdownTableView.scrollToRow(at: IndexPath(row: selectedIndex, section: 0), at: .middle, animated: false)
        }
        
        // Dismiss other dropdowns. This only needs to go one way. This cannot be tapped if the other one is open.
        delegate?.categorySelectorWillShowDropdown()
    }
    
    func hideDropdown() {
        guard isDropdownVisible else { return }
        
        isDropdownVisible = false
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.chevronImageView.transform = .identity
            self.dropdownContainer.alpha = 0
            self.dropdownContainer.transform = CGAffineTransform(scaleX: 0.95, y: 0.95).translatedBy(x: 0, y: -10)
        } completion: { _ in
            self.dropdownContainer.isHidden = true
            self.dropdownContainer.transform = .identity
        }
    }
    
    func updateCategoryDisplay() {
        let currentCategory = CurrentConfiguration.shared.currentCategory
        categoryLabel.text = currentCategory.rawValue
        dropdownTableView.reloadData()
    }
    
    // MARK: - Hit Testing
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Check if point is in dropdown
        if !dropdownContainer.isHidden {
            let dropdownPoint = convert(point, to: dropdownContainer)
            if dropdownContainer.bounds.contains(dropdownPoint) {
                return dropdownTableView.hitTest(convert(point, to: dropdownTableView), with: event)
            }
        }
        
        // Check if point is in container button
        let buttonPoint = convert(point, to: containerButton)
        if containerButton.bounds.contains(buttonPoint) {
            return containerButton
        }
        
        // If dropdown is visible and tap is outside, hide it
        if isDropdownVisible {
            hideDropdown()
        }
        
        return nil
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Expand hit area to include dropdown when visible
        if !dropdownContainer.isHidden {
            let dropdownFrame = dropdownContainer.frame
            if dropdownFrame.contains(point) {
                return true
            }
        }
        return containerButton.frame.contains(point)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension CategorySelectorView: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count - 1 // The minus one is to keep out the 'undefined' category
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryDropdownCell", for: indexPath) as! CategoryDropdownCell
        let category = categories[indexPath.row]
        let isSelected = category == CurrentConfiguration.shared.currentCategory
        cell.configure(with: category, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedCategory = categories[indexPath.row]
        CurrentConfiguration.shared.setCategory(selectedCategory)
        updateCategoryDisplay()
        hideDropdown()
        delegate?.categorySelectorDidSelectCategory(selectedCategory)
    }
}

// MARK: - Category Dropdown Cell
class CategoryDropdownCell: UITableViewCell {
    
    private let iconImageView = UIImageView()
    private let categoryNameLabel = UILabel()
    private let checkmarkImageView = UIImageView()
    
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
        
        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemGray
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconImageView)
        
        // Category name
        categoryNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        categoryNameLabel.textColor = .black
        categoryNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(categoryNameLabel)
        
        // Checkmark
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.tintColor = .systemBlue
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.isHidden = true
        contentView.addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            categoryNameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            categoryNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            categoryNameLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -8),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 18),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    func configure(with category: CurrentSearchCategory, isSelected: Bool) {
        iconImageView.image = UIImage(systemName: category.iconName)
        categoryNameLabel.text = category.rawValue
        checkmarkImageView.isHidden = !isSelected
        
        if isSelected {
            iconImageView.tintColor = .systemBlue
            categoryNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            categoryNameLabel.textColor = .systemBlue
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        } else {
            iconImageView.tintColor = .systemGray
            categoryNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
            categoryNameLabel.textColor = .black
            backgroundColor = .white
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            backgroundColor = UIColor.systemGray5
        } else {
            // Reset based on selection state
            if !checkmarkImageView.isHidden {
                backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
            } else {
                backgroundColor = .white
            }
        }
    }
}
