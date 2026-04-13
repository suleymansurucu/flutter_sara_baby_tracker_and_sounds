import WidgetKit
import SwiftUI

// MARK: - Entry

struct PumpEntry: TimelineEntry {
    let date: Date
    let isRunning: Bool
    let startDate: Date?
    /// 'total' veya 'leftRight'
    let pumpMode: String
    let lastEndDate: Date?
    let babyName: String
    let primaryColor: Color
    let strPump: String
    let strStart: String
    let strStop: String
    let strLastPump: String
    let strLeftSide: String
    let strRightSide: String
}

extension PumpEntry {
    static var placeholder: PumpEntry {
        PumpEntry(
            date: Date(),
            isRunning: true,
            startDate: Date().addingTimeInterval(-312),
            pumpMode: "total",
            lastEndDate: nil,
            babyName: "Sara",
            primaryColor: Color(hex: "#E91E63"),
            strPump: "Pump",
            strStart: "Tap to start",
            strStop: "Tap to pause",
            strLastPump: "Last pump",
            strLeftSide: "Left",
            strRightSide: "Right"
        )
    }
}

// MARK: - Provider

struct PumpProvider: TimelineProvider {

    func placeholder(in context: Context) -> PumpEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (PumpEntry) -> Void) {
        completion(context.isPreview ? .placeholder : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PumpEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> PumpEntry {
        let d = UserDefaults(suiteName: WidgetAppGroup.id)

        let isRunning   = d?.bool(forKey: "pump_running") ?? false
        let startTsMs   = d?.double(forKey: "pump_start_ts") ?? 0
        let startDate: Date? = startTsMs > 0
            ? Date(timeIntervalSince1970: startTsMs / 1000.0) : nil
        let pumpMode    = d?.string(forKey: "pump_mode") ?? "total"
        let lastEndMs   = d?.double(forKey: "pump_last_end_ts") ?? 0
        let lastEndDate: Date? = lastEndMs > 0
            ? Date(timeIntervalSince1970: lastEndMs / 1000.0) : nil
        let babyName    = d?.string(forKey: "w_baby_name") ?? "Baby"
        let primaryHex  = d?.string(forKey: "w_primary_color") ?? "#E91E63"

        return PumpEntry(
            date: Date(),
            isRunning: isRunning,
            startDate: startDate,
            pumpMode: pumpMode,
            lastEndDate: lastEndDate,
            babyName: babyName,
            primaryColor: Color(hex: primaryHex),
            strPump:      d?.string(forKey: "w_str_pump")       ?? "Pump",
            strStart:     d?.string(forKey: "w_str_start")      ?? "Tap to start",
            strStop:      d?.string(forKey: "w_str_stop")       ?? "Tap to pause",
            strLastPump:  d?.string(forKey: "w_str_last_pump")  ?? "Last pump",
            strLeftSide:  d?.string(forKey: "w_str_left_side")  ?? "Left",
            strRightSide: d?.string(forKey: "w_str_right_side") ?? "Right"
        )
    }
}

// MARK: - Small view (2×2)

struct PumpSmallView: View {
    let entry: PumpEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .foregroundColor(WidgetColors.pumpIcon)
                    .font(.system(size: 13, weight: .semibold))
                Text(entry.strPump)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(WidgetColors.textPrimary)
                Spacer()
            }

            Spacer()

            if entry.isRunning, let start = entry.startDate {
                Text(start, style: .timer)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(WidgetColors.pumpIcon)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(entry.strStop)
                    .font(.system(size: 10))
                    .foregroundColor(WidgetColors.textSecondary)
            } else if let lastEnd = entry.lastEndDate {
                Text(entry.strLastPump)
                    .font(.system(size: 10))
                    .foregroundColor(WidgetColors.textSecondary)
                Text(lastEnd, style: .relative)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(WidgetColors.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            } else {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(entry.primaryColor)
                Text(entry.strStart)
                    .font(.system(size: 10))
                    .foregroundColor(WidgetColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WidgetColors.pumpBackground)
    }
}

// MARK: - Medium view (4×2)

struct PumpMediumView: View {
    let entry: PumpEntry

    var body: some View {
        HStack(spacing: 16) {

            // Sol: ikon + bebek adı + mod etiketi
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(WidgetColors.pumpIcon.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: "drop.fill")
                            .foregroundColor(WidgetColors.pumpIcon)
                            .font(.system(size: 17))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.babyName)
                            .font(.system(size: 11))
                            .foregroundColor(WidgetColors.textSecondary)
                        Text(entry.strPump)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(WidgetColors.textPrimary)
                    }
                }

                Spacer()

                // Mod etiketi (Total / Left·Right)
                let modeLabel = entry.pumpMode == "total"
                    ? "Total"
                    : "\(entry.strLeftSide) · \(entry.strRightSide)"
                Text(modeLabel)
                    .font(.system(size: 10))
                    .foregroundColor(WidgetColors.pumpIcon)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(WidgetColors.pumpIcon.opacity(0.12))
                    )
            }
            .frame(maxHeight: .infinity, alignment: .leading)

            // Dikey ayırıcı
            Rectangle()
                .fill(WidgetColors.pumpIcon.opacity(0.2))
                .frame(width: 1)
                .padding(.vertical, 6)

            // Sağ: timer veya bilgi
            VStack(spacing: 6) {
                if entry.isRunning, let start = entry.startDate {
                    Text(start, style: .timer)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(WidgetColors.pumpIcon)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(entry.strStop)
                        .font(.system(size: 10))
                        .foregroundColor(WidgetColors.textSecondary)
                } else if let lastEnd = entry.lastEndDate {
                    Text(entry.strLastPump)
                        .font(.system(size: 10))
                        .foregroundColor(WidgetColors.textSecondary)
                    Text(lastEnd, style: .relative)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(WidgetColors.textPrimary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("ago")
                        .font(.system(size: 10))
                        .foregroundColor(WidgetColors.textSecondary)
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 42))
                        .foregroundColor(entry.primaryColor)
                    Text(entry.strStart)
                        .font(.system(size: 11))
                        .foregroundColor(WidgetColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WidgetColors.pumpBackground)
    }
}

// MARK: - Entry view

struct PumpWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PumpEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                PumpMediumView(entry: entry)
            default:
                PumpSmallView(entry: entry)
            }
        }
        .widgetURL(URL(string: "sarababy://pump"))
    }
}

// MARK: - Widget tanımı

struct PumpWidget: Widget {
    let kind = "PumpWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PumpProvider()) { entry in
            PumpWidgetEntryView(entry: entry)
                .containerBackground(WidgetColors.pumpBackground, for: .widget)
        }
        .configurationDisplayName("Pump Tracker")
        .description("Track your pumping sessions from your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    PumpWidget()
} timeline: {
    PumpEntry.placeholder
}

#Preview(as: .systemMedium) {
    PumpWidget()
} timeline: {
    PumpEntry.placeholder
}
