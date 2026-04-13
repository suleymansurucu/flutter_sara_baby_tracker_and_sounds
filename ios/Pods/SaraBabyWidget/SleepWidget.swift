import WidgetKit
import SwiftUI

// MARK: - Entry (tek snapshot)

struct SleepEntry: TimelineEntry {
    let date: Date
    let isRunning: Bool
    /// Timer başladığında set edilir. Text(startDate, style: .timer) ile
    /// hiç refresh harcamadan canlı sayaç gösterilir.
    let startDate: Date?
    let lastDurationSec: Int
    let lastEndDate: Date?
    let babyName: String
    let primaryColor: Color
    // Flutter'ın yazdığı çevrilmiş string'ler
    let strSleep: String
    let strStart: String
    let strStop: String
    let strLastSleep: String
}

extension SleepEntry {
    static var placeholder: SleepEntry {
        SleepEntry(
            date: Date(),
            isRunning: true,
            startDate: Date().addingTimeInterval(-3661),
            lastDurationSec: 0,
            lastEndDate: nil,
            babyName: "Sara",
            primaryColor: Color(hex: "#E91E63"),
            strSleep: "Sleep",
            strStart: "Tap to start",
            strStop: "Tap to pause",
            strLastSleep: "Last sleep"
        )
    }
}

// MARK: - Provider

struct SleepProvider: TimelineProvider {

    func placeholder(in context: Context) -> SleepEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (SleepEntry) -> Void) {
        completion(context.isPreview ? .placeholder : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepEntry>) -> Void) {
        let entry = loadEntry()
        // Timer çalışırken Text(.timer) kendi kendini günceller, refresh gerekmez.
        // Yine de 30 dakikada bir taze veri alalım (WidgetKit bütçesi minimal).
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> SleepEntry {
        let d = UserDefaults(suiteName: WidgetAppGroup.id)

        let isRunning   = d?.bool(forKey: "sleep_running") ?? false
        let startTsMs   = d?.double(forKey: "sleep_start_ts") ?? 0
        let startDate: Date? = startTsMs > 0
            ? Date(timeIntervalSince1970: startTsMs / 1000.0) : nil
        let lastDur     = d?.integer(forKey: "sleep_last_dur_sec") ?? 0
        let lastEndMs   = d?.double(forKey: "sleep_last_end_ts") ?? 0
        let lastEndDate: Date? = lastEndMs > 0
            ? Date(timeIntervalSince1970: lastEndMs / 1000.0) : nil
        let babyName    = d?.string(forKey: "w_baby_name") ?? "Baby"
        let primaryHex  = d?.string(forKey: "w_primary_color") ?? "#E91E63"

        return SleepEntry(
            date: Date(),
            isRunning: isRunning,
            startDate: startDate,
            lastDurationSec: lastDur,
            lastEndDate: lastEndDate,
            babyName: babyName,
            primaryColor: Color(hex: primaryHex),
            strSleep:     d?.string(forKey: "w_str_sleep")      ?? "Sleep",
            strStart:     d?.string(forKey: "w_str_start")      ?? "Tap to start",
            strStop:      d?.string(forKey: "w_str_stop")       ?? "Tap to pause",
            strLastSleep: d?.string(forKey: "w_str_last_sleep") ?? "Last sleep"
        )
    }
}

// MARK: - Small view (2×2)

struct SleepSmallView: View {
    let entry: SleepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Başlık satırı
            HStack(spacing: 6) {
                Image(systemName: "moon.fill")
                    .foregroundColor(WidgetColors.sleepIcon)
                    .font(.system(size: 13, weight: .semibold))
                Text(entry.strSleep)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(WidgetColors.textPrimary)
                Spacer()
            }

            Spacer()

            // Ana içerik
            if entry.isRunning, let startDate = entry.startDate {
                // Text(.timer) → WidgetKit refresh harcamadan otomatik artar
                Text(startDate, style: .timer)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(WidgetColors.sleepIcon)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(entry.strStop)
                    .font(.system(size: 10))
                    .foregroundColor(WidgetColors.textSecondary)
            } else if entry.lastDurationSec > 0 {
                Text(formatDurationSec(entry.lastDurationSec))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(WidgetColors.textPrimary)
                Text(entry.strLastSleep)
                    .font(.system(size: 10))
                    .foregroundColor(WidgetColors.textSecondary)
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
        .background(WidgetColors.sleepBackground)
    }
}

// MARK: - Medium view (4×2)

struct SleepMediumView: View {
    let entry: SleepEntry

    var body: some View {
        HStack(spacing: 16) {

            // Sol: ikon + bebek adı + son uyku
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(WidgetColors.sleepIcon.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: "moon.fill")
                            .foregroundColor(WidgetColors.sleepIcon)
                            .font(.system(size: 17))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.babyName)
                            .font(.system(size: 11))
                            .foregroundColor(WidgetColors.textSecondary)
                        Text(entry.strSleep)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(WidgetColors.textPrimary)
                    }
                }

                Spacer()

                if !entry.isRunning && entry.lastDurationSec > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.strLastSleep)
                            .font(.system(size: 10))
                            .foregroundColor(WidgetColors.textSecondary)
                        Text(formatDurationSec(entry.lastDurationSec))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(WidgetColors.textPrimary)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .leading)

            // Dikey ayırıcı
            Rectangle()
                .fill(WidgetColors.sleepIcon.opacity(0.2))
                .frame(width: 1)
                .padding(.vertical, 6)

            // Sağ: timer veya başlat
            VStack(spacing: 4) {
                if entry.isRunning, let startDate = entry.startDate {
                    Text(startDate, style: .timer)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(WidgetColors.sleepIcon)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(entry.strStop)
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
        .background(WidgetColors.sleepBackground)
    }
}

// MARK: - Entry view (boyuta göre yönlendir)

struct SleepWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SleepEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                SleepMediumView(entry: entry)
            default:
                SleepSmallView(entry: entry)
            }
        }
        // Tap → uygulamayı sleep ekranında açar
        .widgetURL(URL(string: "sarababy://sleep"))
    }
}

// MARK: - Widget tanımı

struct SleepWidget: Widget {
    let kind = "SleepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepProvider()) { entry in
            SleepWidgetEntryView(entry: entry)
                .containerBackground(WidgetColors.sleepBackground, for: .widget)
        }
        .configurationDisplayName("Sleep Tracker")
        .description("Track your baby's sleep from your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SleepWidget()
} timeline: {
    SleepEntry.placeholder
}

#Preview(as: .systemMedium) {
    SleepWidget()
} timeline: {
    SleepEntry.placeholder
}
