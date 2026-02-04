import WidgetKit
import SwiftUI

struct DashboardEntry: TimelineEntry {
    let date: Date
    let usersCount: Int
    let usersTrend: Int
    let chatsCount: Int
    let chatsTrend: Int
    let msgsCount: Int
    let msgsTrend: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> DashboardEntry {
        DashboardEntry(date: Date(), usersCount: 0, usersTrend: 0, chatsCount: 0, chatsTrend: 0, msgsCount: 0, msgsTrend: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (DashboardEntry) -> ()) {
        let entry = getEntryFromUserDefaults()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getEntryFromUserDefaults()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func getEntryFromUserDefaults() -> DashboardEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.kidastudios.ideaMessengerAdminPortal")
        let usersCount = userDefaults?.integer(forKey: "users_count") ?? 0
        let usersTrend = userDefaults?.integer(forKey: "users_trend") ?? 0
        let chatsCount = userDefaults?.integer(forKey: "chats_count") ?? 0
        let chatsTrend = userDefaults?.integer(forKey: "chats_trend") ?? 0
        let msgsCount = userDefaults?.integer(forKey: "msgs_count") ?? 0
        let msgsTrend = userDefaults?.integer(forKey: "msgs_trend") ?? 0
        
        return DashboardEntry(
            date: Date(), 
            usersCount: usersCount, 
            usersTrend: usersTrend, 
            chatsCount: chatsCount, 
            chatsTrend: chatsTrend, 
            msgsCount: msgsCount, 
            msgsTrend: msgsTrend
        )
    }
}

struct IdeaDeDashboardWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 12) {
            StatItem(label: "Users", count: entry.usersCount, trend: entry.usersTrend, icon: "person.2.fill")
            StatItem(label: "Chats", count: entry.chatsCount, trend: entry.chatsTrend, icon: "bubble.left.and.bubble.right.fill")
            StatItem(label: "Msgs", count: entry.msgsCount, trend: entry.msgsTrend, icon: "text.bubble.fill")
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.14, green: 0.45, blue: 0.95), // primaryBlue (#2472F2)
                    Color(red: 0.31, green: 0.65, blue: 0.94)  // secondaryBlue (#4FA5F0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct StatItem: View {
    let label: String
    let count: Int
    let trend: Int
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.14, green: 0.45, blue: 0.95))
                .frame(height: 24)
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.black.opacity(0.5))
                .textCase(.uppercase)
            
            Text("\(count)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.35)) // High contrast dark blue
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            TrendBadge(trend: trend)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
    }
}

struct TrendBadge: View {
    let trend: Int
    var body: some View {
        HStack(spacing: 2) {
            if trend > 0 {
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
            } else if trend < 0 {
                Image(systemName: "arrow.down.right")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "minus")
                    .foregroundColor(.gray)
            }
        }
        .font(.system(size: 9, weight: .heavy))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.05))
        .cornerRadius(4)
    }
}

struct IdeaDeDashboardWidget: Widget {
    let kind: String = "IdeaDeDashboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            IdeaDeDashboardWidgetView(entry: entry)
        }
        .configurationDisplayName("IdeaDe Control")
        .description("Track your live platform growth.")
        .supportedFamilies([.systemMedium])
    }
}
