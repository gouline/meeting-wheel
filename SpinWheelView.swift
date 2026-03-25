import AppKit
import SwiftUI

struct SpinWheelView: View {
    let names: [String]
    let weights: [Int]
    let onFinished: (String) -> Void

    @State private var rotation: Double = 0
    @State private var isSpinning = false
    @State private var finalName: String? = nil
    @State private var showConfetti = false
    @State private var showResult = false

    // Slice colours — enough variety for most meetings
    private let sliceColours: [Color] = [
        Color(red: 0.35, green: 0.56, blue: 0.97),  // blue
        Color(red: 0.95, green: 0.45, blue: 0.45),  // coral
        Color(red: 0.40, green: 0.78, blue: 0.55),  // green
        Color(red: 0.95, green: 0.72, blue: 0.30),  // amber
        Color(red: 0.65, green: 0.45, blue: 0.85),  // purple
        Color(red: 0.90, green: 0.50, blue: 0.70),  // pink
        Color(red: 0.35, green: 0.75, blue: 0.80),  // teal
        Color(red: 0.85, green: 0.60, blue: 0.35),  // orange
        Color(red: 0.55, green: 0.70, blue: 0.40),  // olive
        Color(red: 0.70, green: 0.50, blue: 0.65),  // mauve
    ]

    private var totalWeight: Double {
        Double(weights.reduce(0, +))
    }

    // Returns (startAngle, endAngle) in degrees for each slice
    private var sliceAngles: [(start: Double, end: Double)] {
        var result: [(start: Double, end: Double)] = []
        var current: Double = 0
        for w in weights {
            let angle = 360.0 * Double(w) / totalWeight
            result.append((start: current, end: current + angle))
            current += angle
        }
        return result
    }

    // Pre-computed color indices ensuring no two adjacent slices (including wrap-around) share a color
    private var sliceColourIndices: [Int] {
        let n = names.count
        let paletteSize = sliceColours.count
        if n == 0 { return [] }
        if n == 1 { return [0] }

        var indices: [Int] = []
        // Alternate between two halves of the palette
        let half = paletteSize / 2
        for i in 0..<n {
            if i % 2 == 0 {
                indices.append((i / 2) % half)
            } else {
                indices.append(half + (i / 2) % half)
            }
        }
        // Fix wrap-around: if last color matches first, swap last with a safe alternative
        if n > 2 && indices[n - 1] == indices[0] {
            let used = Set([indices[0], indices[n - 2]])
            for c in 0..<paletteSize {
                if !used.contains(c) {
                    indices[n - 1] = c
                    break
                }
            }
        }
        return indices
    }

    private func colourForSlice(_ index: Int) -> Color {
        sliceColours[sliceColourIndices[index]]
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // The wheel
                ZStack {
                    ForEach(0..<names.count, id: \.self) { index in
                        let angles = sliceAngles[index]
                        WheelSlice(
                            startAngle: .degrees(angles.start),
                            endAngle: .degrees(angles.end),
                            colour: colourForSlice(index)
                        )
                    }

                    // Slice labels
                    ForEach(0..<names.count, id: \.self) { index in
                        let angles = sliceAngles[index]
                        let sliceSize = angles.end - angles.start
                        let midAngle = (angles.start + angles.end) / 2.0 - 90
                        SliceLabel(text: names[index], angle: midAngle, radius: 250, sliceAngle: sliceSize)
                    }
                }
                .frame(width: 520, height: 520)
                .rotationEffect(.degrees(rotation))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                // Centre cap
                Circle()
                    .fill(.white)
                    .frame(width: 42, height: 42)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                // Pointer (bottom)
                VStack {
                    Spacer()
                    Triangle()
                        .fill(.red)
                        .frame(width: 30, height: 26)
                        .rotationEffect(.degrees(180))
                        .shadow(color: .black.opacity(0.15), radius: 2, y: -1)
                }
                .frame(height: 546)
            }

            // Result / buttons
            if showResult, let name = finalName {
                Text(name)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .transition(.scale.combined(with: .opacity))

                Button("Done") {
                    onFinished(name)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Text(" ")
                    .font(.system(.title, design: .rounded, weight: .bold))

                Button(isSpinning ? "Spinning…" : "Spin!") {
                    spin()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSpinning)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Small delay then auto-spin
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                spin()
            }
        }
    }

    private func spin() {
        guard !isSpinning else { return }
        isSpinning = true
        showResult = false
        showConfetti = false
        finalName = nil

        // Pick a weighted random winner
        let totalW = weights.reduce(0, +)
        var roll = Int.random(in: 0..<totalW)
        var winnerIndex = 0
        for i in 0..<weights.count {
            roll -= weights[i]
            if roll < 0 { winnerIndex = i; break }
        }

        // Calculate target rotation:
        // The pointer is at the bottom (180°). Slices are drawn with a -90° offset,
        // so slice 0 starts at the top. SwiftUI rotates clockwise for positive values.
        // After rotation R, the slice at original angle A appears at (A + R) mod 360.
        // We want a random point within the winner's slice to land at 180° (bottom / pointer).
        let winnerAngles = sliceAngles[winnerIndex]
        let sliceSize = winnerAngles.end - winnerAngles.start
        let edgeMargin = sliceSize * 0.1
        let randomOffset = Double.random(in: edgeMargin...(sliceSize - edgeMargin))
        let targetPoint = winnerAngles.start + randomOffset
        let targetMod = fmod(360.0 + 180.0 - targetPoint, 360.0)
        // Add several full rotations for visual effect
        let fullSpins = Double(Int.random(in: 3...4)) * 360.0
        let targetRotation = rotation + fullSpins + targetMod - fmod(rotation, 360.0)

        // Smooth spin that ramps up gently and decelerates gradually at the end
        let duration: Double = 7.0
        withAnimation(
            .timingCurve(0.08, 0.55, 0.1, 1.0, duration: duration)
        ) {
            rotation = targetRotation
        }

        // Reveal result after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            finalName = names[winnerIndex]
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showResult = true
            }
            isSpinning = false
            showConfetti = true
            Self.playTadaa()
        }
    }

    private static func playTadaa() {
        NSSound(contentsOfFile: "/System/Library/Sounds/Glass.aiff", byReference: true)?.play()
    }
}

// MARK: - Wheel Slice Shape

struct WheelSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let colour: Color

    var body: some View {
        GeometryReader { geo in
            let centre = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2

            Path { path in
                path.move(to: centre)
                path.addArc(
                    center: centre,
                    radius: radius,
                    startAngle: startAngle - .degrees(90),
                    endAngle: endAngle - .degrees(90),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(colour)

            // Subtle border between slices
            Path { path in
                path.move(to: centre)
                path.addArc(
                    center: centre,
                    radius: radius,
                    startAngle: startAngle - .degrees(90),
                    endAngle: endAngle - .degrees(90),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .stroke(.white.opacity(0.4), lineWidth: 1.5)
        }
    }
}

// MARK: - Slice Label

struct SliceLabel: View {
    let text: String
    let angle: Double
    let radius: CGFloat
    let sliceAngle: Double

    var body: some View {
        // Truncate long names
        let displayText = text.count > 20 ? String(text.prefix(18)) + "…" : text

        // Scale font size down for many slices
        let fontSize: CGFloat = sliceAngle > 40 ? 20 : sliceAngle > 25 ? 16 : 14

        let labelRadius: CGFloat = radius * 0.62
        let angleRad: CGFloat = CGFloat(angle) * .pi / 180

        Text(displayText)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
            .rotationEffect(.degrees(angle))
            .offset(
                x: cos(angleRad) * labelRadius,
                y: sin(angleRad) * labelRadius
            )
    }
}

// MARK: - Pointer Triangle

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Confetti

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let spinSpeed: Double
    let delay: Double
}

struct ConfettiView: View {
    @State private var animate = false

    private let pieces: [ConfettiPiece] = (0..<60).map { _ in
        ConfettiPiece(
            x: CGFloat.random(in: 0...1),
            color: [
                Color.red, .blue, .green, .yellow, .orange, .pink, .purple, .mint
            ].randomElement()!,
            size: CGFloat.random(in: 6...12),
            rotation: Double.random(in: 0...360),
            spinSpeed: Double.random(in: 200...600),
            delay: Double.random(in: 0...0.3)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.6)
                    .rotationEffect(.degrees(animate ? piece.rotation + piece.spinSpeed : piece.rotation))
                    .position(
                        x: piece.x * geo.size.width,
                        y: animate ? geo.size.height + 20 : -20
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeIn(duration: Double.random(in: 2.0...3.5)).delay(piece.delay),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}
