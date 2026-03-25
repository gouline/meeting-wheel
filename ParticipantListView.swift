import SwiftUI

struct Participant: Identifiable {
    let id = UUID()
    let name: String
    var enabled: Bool = true
    var weight: Int = 1
}

struct ParticipantListView: View {
    let meeting: Meeting
    let onBack: () -> Void

    @State private var participants: [Participant] = []
    @State private var newName: String = ""
    @State private var showWheel = false
    @State private var winner: String? = nil

    var enabledParticipants: [Participant] {
        participants.filter(\.enabled)
    }

    var body: some View {
        VStack(spacing: 0) {
            if showWheel {
                SpinWheelView(
                    names: enabledParticipants.map(\.name),
                    weights: enabledParticipants.map(\.weight),
                    onFinished: { selected in
                        winner = selected
                        showWheel = false
                    }
                )
            } else {
                // Header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Back")
                                .font(.system(.body, design: .rounded))
                        }
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(meeting.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text(meeting.timeString)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                Divider()


                // Participant list
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach($participants) { $participant in
                            HStack(spacing: 12) {
                                Toggle(isOn: $participant.enabled) {
                                    Text(participant.name)
                                        .font(.system(.body, design: .rounded))
                                        .foregroundStyle(participant.enabled ? .primary : .secondary)
                                }
                                .toggleStyle(.checkbox)

                                Spacer()

                                HStack(spacing: 4) {
                                    Button {
                                        if participant.weight > 1 { participant.weight -= 1 }
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.system(size: 10, weight: .bold))
                                            .frame(width: 20, height: 20)
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(!participant.enabled || participant.weight <= 1)

                                    Text("\(participant.weight)")
                                        .font(.system(.body, design: .monospaced, weight: .medium))
                                        .frame(width: 24, alignment: .center)

                                    Button {
                                        if participant.weight < 5 { participant.weight += 1 }
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .bold))
                                            .frame(width: 20, height: 20)
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(!participant.enabled || participant.weight >= 5)
                                }
                                .foregroundStyle(participant.enabled ? .primary : .secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.vertical, 12)
                }

                Divider()

                // Add participant
                HStack(spacing: 10) {
                    TextField("Add participant…", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .rounded))
                        .onSubmit { addParticipant() }

                    Button(action: addParticipant) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                    .buttonStyle(.borderless)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                // Spin button
                Button(action: {
                    showWheel = true
                    winner = nil
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Spin the Wheel")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(enabledParticipants.count < 2)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            participants = meeting.attendees.map {
                Participant(name: $0.displayName, enabled: true, weight: Int.random(in: 1...5))
            }
        }
    }

    private func addParticipant() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        participants.append(Participant(name: trimmed, enabled: true, weight: Int.random(in: 1...5)))
        newName = ""
    }
}
