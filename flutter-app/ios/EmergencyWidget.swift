import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), name: "홍길동", blood: "A+", contact: "010-1234-5678")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getEmergencyEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getEmergencyEntry()
        // Reload is managed programmatically from Flutter through AppDelegate (WidgetCenter.reloadAllTimelines)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
    
    private func getEmergencyEntry() -> SimpleEntry {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.devbeaver.qrdoc") {
            let name = sharedDefaults.string(forKey: "name") ?? "미등록"
            let blood = sharedDefaults.string(forKey: "blood") ?? "미등록"
            let contact = sharedDefaults.string(forKey: "contact") ?? "미등록"
            return SimpleEntry(date: Date(), name: name, blood: blood, contact: contact)
        }
        return SimpleEntry(date: Date(), name: "미등록", blood: "미등록", contact: "미등록")
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let name: String
    let blood: String
    let contact: String
}

struct EmergencyWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("🚨")
                Text("VitalPass 의료 패스")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 2)
            
            Text("이름: \(entry.name)")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
            
            Text("혈액형: \(entry.blood)")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
            
            Text("비상연락: \(entry.contact)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.6))
                .padding(.bottom, 2)
            
            // SwiftUI Link triggers deep-linking into Flutter MainActivity routing
            Link(destination: URL(string: "qrdoc://emergency")!) {
                Text("터치하여 패스 열기")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.73, green: 0.1, blue: 0.1)) // Emergency Red #BA1A1A
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.12, green: 0.16, blue: 0.23)) // Slate dark #1E293B
    }
}

@main
struct EmergencyWidget: Widget {
    let kind: String = "EmergencyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            EmergencyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("VitalPass 비상 의료 카드")
        .description("잠금화면 우회 응급 카드를 즉시 진입하는 단축 버튼 위젯입니다.")
        .supportedFamilies([.systemSmall])
    }
}
