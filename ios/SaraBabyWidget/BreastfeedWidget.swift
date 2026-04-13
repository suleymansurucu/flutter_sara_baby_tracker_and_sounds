import WidgetKit
import SwiftUI

// MARK: - Entry

struct BreastfeedEntry: TimelineEntry {
    let date: Date
    let leftRunning: Bool
    let leftStartDate: Date?
    let rightRunning: Bool
    let rightStartDate: Date?
    let lastEndDate: Date?
    let babyName: String
    let primaryColor: Color
    let strFeed: String
    let strLeftSide: String
    let strRightSide: String
    let strStart: String
    let strStop: String
    let strLastFeed: String
}

extension BreastfeedEntry {
    static var placeholder: BreastfeedEntry {
        BreastfeedEntry(
            date: Date(),
            leftRunning: true,
            leftStartDate: Date().addingTimeInterval(-185),
            rightRunning: false,
            rightStartDate: nil,
            lastEndDate: nil,
            babyName: "Sara",
            primaryColor: Color(hex: "#E91E63"),
            strFeed: "Breastfeed",
            strLeftSide: "Left",
            strRightSide: "Right",
            strStart: "Tap to start",
            strStop: "Tap to pause",
            strLastFeed: "Last feed"
        )
    }
}

// MARK: - Provider

struct BreastfeedProvider: TimelineProvider {

    func placeholder(in context: Context) -> BreastfeedEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (BreastfeedEntry) -> Void) {
        completion(context.isPreview ? .placeholder : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BreastfeedEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> BreastfeedEntry {
        let d = UserDefaults(suiteName: WidgetAppGroup.id)

        let leftRunning    = d?.bool(forKey: "bf_left_running") ?? false
        let leftTsMs       = d?.double(forKey: "bf_left_start_ts") ?? 0
        let leftStartDate: Date? = leftTsMs > 0
            ? Date(timeIntervalSince1970: leftTsMs / 1000.0) : nil

        let rightRunning   = d?.bool(forKey: "bf_right_running") ?? false
        let rightTsMs      = d?.double(forKey: "bf_right_start_ts") ?? 0
        let rightStartDate: Date? = rightTsMs > 0
            ? Date(timeIntervalSince1970: rightTsMs / 1000.0) : nil

        let lastEndMs      = d?.double(forKey: "bf_last_end_ts") ?? 0
        let lastEndDate: Date? = lastEndMs > 0
            ? Date(timeIntervalSince1970: lastEndMs / 1000.0) : nil

        let babyName       = d?.string(forKey: "w_baby_name") ?? "Baby"
        let primaryHex     = d?.string(forKey: "w_primary_color") ?? "#E91E63"

        return BreastfeedEntry(
            date: Date(),
            leftRunning: leftRunning,
            leftStartDate: leftStartDate,
            rightRunning: rightRunning,
            rightStartDate: rightStartDate,
            lastEndDate: lastEndDate,
            babyName: babyName,
            primaryColor: Color(hex: primaryHex),
            strFeed:      d?.string(forKey: "w_str_feed")       ?? "Breastfeed",
            strLeftSide:  d?.string(forKey: "w_str_left_side")  ?? "Left",
            strRightSide: d?.string(forKey: "w_str_right_side") ?? "Right",
            strStart:     d?.string(forKey: "w_str_start")      ?? "Tap to start",
            strStop:      d?.string(forKey: "w_str_stop")       ?? "Tap to pause",
            strLastFeed:  d?.string(forKey: "w_str_last_feed")  ?? "Last feed"
        )
    }
}

// MARK: - Side timer view (Sol veya Sağ)

private struct SideTimerView: View {
    let label: String
    let isRunning: Bool
    let startDate: Date?
    let primaryColor: Color
    let strStart: String
    let strStop: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(WidgetColors.textSecondary)

            if isRunning, let start = startDate {
                // Pil tüketmeden canlı sayaç
                Text(start, style: .timer)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(WidgetColors.feedIcon)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(strStop)
                    .font(.system(size: 9))
                    .foregroundColor(WidgetColors.textSecondary)
            } else {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(primaryColor.opacity(0.7))
                Text(strStart)
                    .font(.system(size: 9))
                    .foregroundColor(WidgetColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isRunning
                      ? WidgetColors.feedIcon.opacity(0.12)
                      : Color.white.opacity(0.5))
        )
    }
}

// MARK: - Medium view (4×2) — tek desteklenen boyut

struct BreastfeedMediumView: View {
    let entry: BreastfeedEntry

    var body: some View {
        VStack(spacing: 8) {

            // Başlık
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(WidgetColors.feedIcon.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Text("🤱")
                        .font(.system(size: 15))
                }
                Text(entry.strFeed)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(WidgetColors.textPrimary)
                Spacer()
                Text(entry.babyName)
                    .font(.system(size: 11))
                    .foregroundColor(WidgetColors.textSecondary)
            }

            // Sol / Sağ taraf yan yana
            HStack(spacing: 10) {
                SideTimerView(
                    label: entry.strLeftSide,
                    isRunning: entry.leftRunning,
                    startDate: entry.leftStartDate,
                    primaryColor: entry.primaryColor,
                    strStart: entry.strStart,
                    strStop: entry.strStop
                )

                // Dikey ayırıcı
                Rectangle()
                    .fill(WidgetColors.feedIcon.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 4)

                SideTimerView(
                    label: entry.strRightSide,
                    isRunning: entry.rightRunning,
                    startDate: entry.rightStartDate,
                    primaryColor: entry.primaryColor,
                    strStart: entry.strStart,
                    strStop: entry.strStop
                )
            }

            // Son besleme zamanı (ikisi de duruyorsa)
            if !entry.leftRunning && !entry.rightRunning,
               let lastEnd = entry.lastEndDate {
                HStack(spacing: 4) {
                    Text(entry.strLastFeed + ":")
                        .font(.system(size: 10))
                        .foregroundColor(WidgetColors.textSecondary)
                    Text(lastEnd, style: .relative)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(WidgetColors.textSecondary)
                    Text("ago")
                        .font(.system(size: 10))
                        .foregroundColor(WidgetColors.textSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WidgetColors.feedBackground)
    }
}

// MARK: - Small view (2×2) — en aktif tarafı göster

struct BreastfeedSmallView: View {
    let entry: BreastfeedEntry

    // Aktif olan tarafı öne çıkar; ikisi de aktif değilse sol göster
    private var activeLabel: String {
        if entry.rightRunning && !entry.leftRunning { return entry.strRightSide }
        return entry.strLeftSide
    }
    private var activeRunning: Bool {
        entry.leftRunning || entry.rightRunning
    }
    private var activeStartDate: Date? {
        if entry.rightRunning && !entry.leftRunning { return entry.rightStartDate }
        return entry.leftStartDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Text("🤱")
                    .font(.system(size: 13))
                Text(entry.strFeed)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(WidgetColors.textPrimary)
                Spacer()
            }

            Spacer()

            if activeRunning, let start = activeStartDate {
                Text(activeLabel)
                    .font(.system(size: 10))
                    .foregroundColor(WidgetColors.textSecondary)
                Text(start, style: .timer)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(WidgetColors.feedIcon)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            } else {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(entry.primaryColor)
                Text(entry.strStart)
                    .font(.system(size: 10))
                    .foregroundColor(WidgetColors.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WidgetColors.feedBackground)
    }
}

// MARK: - Entry view

struct BreastfeedWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BreastfeedEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                BreastfeedMediumView(entry: entry)
            default:
                BreastfeedSmallView(entry: entry)
            }
        }
        .widgetURL(URL(string: "sarababy://breastfeed"))
    }
}

// MARK: - Widget tanımı

struct BreastfeedWidget: Widget {
    let kind = "BreastfeedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BreastfeedProvider()) { entry in
            BreastfeedWidgetEntryView(entry: entry)
                .containerBackground(WidgetColors.feedBackground, for: .widget)
        }
        .configurationDisplayName("Breastfeed Tracker")
        .description("Track left and right side breastfeeding from your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    BreastfeedWidget()
} timeline: {
    BreastfeedEntry.placeholder
}

#Preview(as: .systemSmall) {
    BreastfeedWidget()
} timeline: {
    BreastfeedEntry.placeholder
}
