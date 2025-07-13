//
//  Extensions.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import SwiftUI
import Foundation
import UIKit

// MARK: - Date Extensions
extension Date {
    /// Get the start of the day
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Check if this date is the same day as another date
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    /// Format the date with a specific style
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions
extension String {
    /// Check if the string is blank (empty or only whitespace)
    var isBlank: Bool {
        return allSatisfy { $0.isWhitespace }
    }
    
    /// Trim whitespace and newlines
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - View Extensions
extension View {
    /// Apply a corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Custom Shapes
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Utility Functions
/// Format a duration in seconds to a readable string
func formatDuration(_ seconds: Int) -> String {
    if seconds < 60 {
        return "\(seconds)s"
    } else if seconds < 3600 {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return remainingSeconds > 0 ? "\(minutes)m \(remainingSeconds)s" : "\(minutes)m"
    } else {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
}
