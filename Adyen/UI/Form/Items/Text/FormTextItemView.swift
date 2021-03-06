//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import UIKit

/// The interface of the delegate of a text item view.
/// :nodoc:
public protocol FormTextItemViewDelegate: FormValueItemViewDelegate {
    
    /// Invoked when the text entered in the item view's text field has reached the maximum length.
    ///
    /// - Parameter itemView: The item view in which the maximum length was reached.
    func didReachMaximumLength(in itemView: FormTextItemView)
    
    /// Invoked when the return key in the item view's text field is selected.
    ///
    /// - Parameter itemView: The item view in which the return key was selected.
    func didSelectReturnKey(in itemView: FormTextItemView)
    
}

/// A view representing a text item.
/// :nodoc:
open class FormTextItemView: FormValueItemView<FormTextItem>, UITextFieldDelegate {
    
    /// Initializes the text item view.
    ///
    /// - Parameter item: The item represented by the view.
    public required init(item: FormTextItem) {
        super.init(item: item)
        
        addSubview(stackView)
        
        backgroundColor = item.style.backgroundColor
        
        configureConstraints()
    }
    
    /// :nodoc:
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var textDelegate: FormTextItemViewDelegate? {
        return delegate as? FormTextItemViewDelegate
    }
    
    // MARK: - Stack View
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, textField])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 3.0
        stackView.backgroundColor = item.style.backgroundColor
        stackView.preservesSuperviewLayoutMargins = true
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    // MARK: - Title Label
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = item.style.title.font
        titleLabel.textColor = item.style.title.color
        titleLabel.textAlignment = item.style.title.textAlignment
        titleLabel.backgroundColor = item.style.title.backgroundColor
        titleLabel.text = item.title
        titleLabel.isAccessibilityElement = false
        titleLabel.accessibilityIdentifier = item.identifier.map { ViewIdentifierBuilder.build(scopeInstance: $0, postfix: "titleLabel") }
        
        return titleLabel
    }()
    
    // MARK: - Text Field
    
    internal lazy var textField: UITextField = {
        let textField = TextField()
        textField.font = item.style.text.font
        textField.textColor = item.style.text.color
        textField.textAlignment = item.style.text.textAlignment
        textField.backgroundColor = item.style.backgroundColor
        setPlaceHolderText(to: textField)
        textField.autocorrectionType = item.autocorrectionType
        textField.autocapitalizationType = item.autocapitalizationType
        textField.keyboardType = item.keyboardType
        textField.returnKeyType = .next
        textField.accessibilityLabel = item.title
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange(textField:)), for: .editingChanged)
        textField.accessibilityIdentifier = item.identifier.map { ViewIdentifierBuilder.build(scopeInstance: $0, postfix: "textField") }
        
        return textField
    }()
    
    private func setPlaceHolderText(to textField: TextField) {
        if let placeholderStyle = item.style.placeholderText, let placeholderText = item.placeholder {
            apply(textStyle: placeholderStyle, to: textField, with: placeholderText)
        } else {
            textField.placeholder = item.placeholder
        }
    }
    
    private func apply(textStyle: TextStyle, to textField: TextField, with placeholderText: String) {
        let attributes = stringAttributes(from: textStyle)
        let attributedString = NSAttributedString(string: placeholderText, attributes: attributes)
        textField.attributedPlaceholder = attributedString
    }
    
    private func stringAttributes(from textStyle: TextStyle) -> [NSAttributedString.Key: Any] {
        var attributes = [NSAttributedString.Key.foregroundColor: textStyle.color,
                          NSAttributedString.Key.backgroundColor: textStyle.backgroundColor,
                          NSAttributedString.Key.font: textStyle.font]
        
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.alignment = item.style.placeholderText?.textAlignment ?? .natural
        if let paragraphStyle = paragraphStyle {
            attributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        }
        
        return attributes
    }
    
    @objc private func textDidChange(textField: UITextField) {
        let newText = textField.text
        var sanitizedText = newText.map { item.formatter?.sanitizedValue(for: $0) ?? $0 } ?? ""
        let maximumLength = item.validator?.maximumLength(for: sanitizedText) ?? .max
        sanitizedText = sanitizedText.truncate(to: maximumLength)
        
        item.value = sanitizedText
        
        textDelegate?.didChangeValue(in: self)
        
        if sanitizedText.count == maximumLength {
            textDelegate?.didReachMaximumLength(in: self)
        }
        
        if let formatter = item.formatter, let newText = newText {
            textField.text = formatter.formattedValue(for: newText)
        }
    }
    
    // MARK: - Editing
    
    /// :nodoc:
    public override var isEditing: Bool {
        didSet {
            titleLabel.textColor = isEditing ? tintColor : item.style.title.color
        }
    }
    
    // MARK: - Layout
    
    private func configureConstraints() {
        let constraints = [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    open override var lastBaselineAnchor: NSLayoutYAxisAnchor {
        return textField.lastBaselineAnchor
    }
    
    // MARK: - Interaction
    
    /// :nodoc:
    open override var canBecomeFirstResponder: Bool {
        return textField.canBecomeFirstResponder
    }
    
    /// :nodoc:
    @discardableResult
    open override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    /// :nodoc:
    @discardableResult
    open override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    /// :nodoc:
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        _ = becomeFirstResponder()
    }
    
    // MARK: - UITextFieldDelegate
    
    /// :nodoc:
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        isEditing = true
    }
    
    /// :nodoc:
    public func textFieldDidEndEditing(_ textField: UITextField) {
        isEditing = false
    }
    
    /// :nodoc:
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textDelegate?.didSelectReturnKey(in: self)
        
        return true
    }
    
}

/// A UITextField subclass to override the default UITextField default Accessibility behaviour,
/// specifically the voice over reading of the UITextField.placeholder.
/// So in order to prevent this behaviour,
/// accessibilityValue is overriden to return an empty string in case the text var is nil or empty string.
private final class TextField: UITextField {
    var disablePlaceHolderAccessibility: Bool = true
    
    override var accessibilityValue: String? {
        get {
            guard disablePlaceHolderAccessibility else { return super.accessibilityValue }
            if let text = super.text, !text.isEmpty {
                return super.accessibilityValue
            } else {
                return ""
            }
        }
        
        set {
            super.accessibilityValue = newValue
        }
    }
}
