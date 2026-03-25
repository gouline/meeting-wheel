import SwiftUI

struct MeetingListView: View {
    let meetings: [Meeting]
    let onSelect: (Meeting) -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meeting Wheel")
                        .font(.system(.title, design: .rounded, weight: .bold))
                }
                Spacer()
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help("Refresh meetings")
            }
            .padding(24)

            Divider()

            if meetings.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("No upcoming meetings")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(meetings) { meeting in
                            MeetingRow(meeting: meeting)
                                .onTapGesture { onSelect(meeting) }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}

struct MeetingRow: View {
    let meeting: Meeting

    var body: some View {
        HStack(spacing: 14) {
            // Time indicator
            VStack(spacing: 2) {
                let fmt = DateFormatter()
                let _ = fmt.dateFormat = "HH:mm"
                Text(fmt.string(from: meeting.startDate))
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                Text(fmt.string(from: meeting.endDate))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 52)

            RoundedRectangle(cornerRadius: 1.5)
                .fill(.blue.opacity(0.6))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .lineLimit(1)

                let count = meeting.attendees.count
                if count > 0 {
                    Text("\(count) participant\(count == 1 ? "" : "s")")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No participants")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
        .contentShape(Rectangle())
    }
}
