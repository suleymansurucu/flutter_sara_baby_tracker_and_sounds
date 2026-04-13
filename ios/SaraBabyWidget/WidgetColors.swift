import SwiftUI

// MARK: - Paylaşılan sabitler

enum WidgetAppGroup {
    static let id = "group.com.suleymansurucu.sarababy"
}

// Flutter'daki AppColors ile birebir eşleşen sabitler
enum WidgetColors {
    static let sleepBackground = Color(hex: "#D9E4FF")
    static let sleepIcon       = Color(hex: "#7C6CF7")
    static let pumpBackground  = Color(hex: "#FFD6E8")
    static let pumpIcon        = Color(hex: "#FF6F91")
    static let feedBackground  = Color(hex: "#FFF4CC")
    static let feedIcon        = Color(hex: "#F5A623")
    static let textPrimary     = Color(hex: "#3D3D3D")
    static let textSecondary   = Color(hex: "#888888")
}

// MARK: - Hex renk desteği

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 200, 200, 200)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Duration formatlama

func formatDurationSec(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    if h > 0 { return "\(h)h \(m)m" }
    if m > 0 { return "\(m)m" }
    return "<1m"
}
