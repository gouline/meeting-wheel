import SwiftUI

struct ContentView: View {
    @StateObject private var calendarManager = CalendarManager()
    @State private var selectedMeeting: Meeting?
    @State private var showWheel = false

    var body: some View {
        Group {
            if calendarManager.accessDenied {
                AccessDeniedView()
            } else if !calendarManager.accessGranted {
                LoadingView()
            } else if let meeting = selectedMeeting, showWheel {
                // This state is unused now — wheel is shown inside ParticipantListView
                // Kept for potential future use
                ParticipantListView(
                    meeting: meeting,
                    onBack: {
                        selectedMeeting = nil
                        showWheel = false
                        calendarManager.fetchMeetings()
                    }
                )
            } else if let meeting = selectedMeeting {
                ParticipantListView(
                    meeting: meeting,
                    onBack: {
                        selectedMeeting = nil
                        calendarManager.fetchMeetings()
                    }
                )
            } else {
                MeetingListView(
                    meetings: calendarManager.meetings,
                    onSelect: { meeting in
                        selectedMeeting = meeting
                    },
                    onRefresh: {
                        calendarManager.fetchMeetings()
                    }
                )
            }
        }
        .onAppear {
            calendarManager.requestAccess()
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Requesting calendar access…")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AccessDeniedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.red.opacity(0.7))
            Text("Calendar Access Required")
                .font(.system(.title2, design: .rounded, weight: .semibold))
            Text("Grant access in System Settings → Privacy & Security → Calendars")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
