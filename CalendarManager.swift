import EventKit
import Foundation

struct Meeting: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let attendees: [Attendee]

    var timeString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return "\(fmt.string(from: startDate)) – \(fmt.string(from: endDate))"
    }
}

struct Attendee: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let email: String?
    let isOrganiser: Bool

    var displayName: String {
        if !name.isEmpty && !name.contains("@") { return name }
        let nameOrEmail = name.contains("@") ? name : email
        if let email = nameOrEmail {
            let local = email.components(separatedBy: "@").first ?? email
            let parts = local.components(separatedBy: CharacterSet.alphanumerics.inverted)
            let formatted = parts.filter { !$0.isEmpty }.map { $0.capitalized }.joined(separator: " ")
            if !formatted.isEmpty { return formatted }
            return email
        }
        return "Unknown"
    }
}

class CalendarManager: ObservableObject {
    private let store = EKEventStore()
    @Published var meetings: [Meeting] = []
    @Published var accessGranted = false
    @Published var accessDenied = false

    func requestAccess() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.accessGranted = granted
                    self.accessDenied = !granted
                    if granted { self.fetchMeetings() }
                }
            }
        } else {
            store.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.accessGranted = granted
                    self.accessDenied = !granted
                    if granted { self.fetchMeetings() }
                }
            }
        }
    }

    func fetchMeetings() {
        let now = Date()
        let lookBack: TimeInterval = 24 * 3600
        let lookAhead: TimeInterval = 24 * 3600
        let start = now.addingTimeInterval(-lookBack)
        let end = now.addingTimeInterval(lookAhead)

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = store.events(matching: predicate)

        let filtered = ekEvents.filter { !$0.isAllDay && $0.endDate > now }
        let sorted = filtered.sorted { $0.startDate < $1.startDate }
        let top5 = sorted.prefix(5)
        let results: [Meeting] = top5.map { event in
            return self.makeMeeting(from: event)
        }

        DispatchQueue.main.async {
            self.meetings = results
        }
    }

    private func makeMeeting(from event: EKEvent) -> Meeting {
        let participants: [EKParticipant] = event.attendees ?? []
        let unsorted: [Attendee] = participants.map { participant in
            let name: String = participant.name ?? ""
            let email: String? = participant.url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
            let isOrganiser: Bool = participant.isCurrentUser == false && participant.participantRole == .chair
            return Attendee(name: name, email: email, isOrganiser: isOrganiser)
        }
        let attendees: [Attendee] = unsorted.sorted { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        let meetingId: String = event.eventIdentifier ?? UUID().uuidString
        let title: String = event.title ?? "Untitled"
        return Meeting(
            id: meetingId,
            title: title,
            startDate: event.startDate,
            endDate: event.endDate,
            attendees: attendees
        )
    }
}
