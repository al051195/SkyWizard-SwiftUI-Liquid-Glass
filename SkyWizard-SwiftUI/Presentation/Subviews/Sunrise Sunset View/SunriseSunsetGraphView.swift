//
//  SunriseSunsetGraphView.swift
//  SkyWizard-SwiftUI
//
//  Created by Antoine LEPRETRE on 06/09/2026.
//

import SwiftUI
import SkyWizardModel

struct SunriseSunsetGraphView: View {
    let sunrise: Date?
    let sunset: Date?
    let dayLength: String?
    let timeZone: TimeZone
    @Binding var scrubProgress: CGFloat?

    @EnvironmentObject private var settings: SettingsStore

    init(
        sunrise: Date?,
        sunset: Date?,
        dayLength: String? = nil,
        timeZone: TimeZone = .current,
        scrubProgress: Binding<CGFloat?> = .constant(nil)
    ) {
        self.sunrise = sunrise
        self.sunset = sunset
        self.dayLength = dayLength
        self.timeZone = timeZone
        self._scrubProgress = scrubProgress
    }

    var body: some View {
        Group {
            if let sunrise, let sunset, sunset > sunrise {
                SunArcTrack(sunrise: sunrise, sunset: sunset, dayLength: dayLength, timeZone: timeZone, scrubProgress: $scrubProgress)
            } else {
                unavailableView
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 33))
    }
}

private extension SunriseSunsetGraphView {
    var unavailableView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "cloud.slash")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.daySubTitle)
            Text("Sunrise & sunset times are not available for this forecast.")
                .font(.getFont(type: .medium, size: 14))
                .foregroundStyle(.daySubTitle)
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .center)
        .multilineTextAlignment(.center)
    }
}

/// The day drawn as a horizon dial. A dashed arc traces the full path and a
/// gradient arc covers the daylight so far; the sun rides the arc as a small
/// glass disc, and dragging across the card scrubs it (driving the house
/// light through `scrubProgress`).
private struct SunArcTrack: View {
    let sunrise: Date
    let sunset: Date
    let dayLength: String?
    let timeZone: TimeZone
    @Binding var scrubProgress: CGFloat?

    @State private var now = Date()
    @State private var isScrubbing = false
    /// Fraction where the current scrub began, so the sun starts moving from
    /// where it is instead of teleporting under the finger.
    @State private var scrubStartFraction: CGFloat = 0
    /// Drives the eased ride home after release; cancelled by a new scrub.
    @State private var returnTask: Task<Void, Never>?

    private var displayedFraction: CGFloat {
        scrubProgress ?? fraction(for: now)
    }

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { proxy in
                arcLayer(in: proxy.size)
                    .contentShape(Rectangle())
                    .simultaneousGesture(scrubGesture(width: proxy.size.width))
            }
            .frame(height: 120)

            horizonRow
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            now = .now
        }
    }

    // MARK: Arc

    private func arcLayer(in size: CGSize) -> some View {
        ZStack {
            SunArc()
                .stroke(.daySubTitle.opacity(0.35), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 6]))

            SunArc()
                .trim(from: 0, to: min(max(displayedFraction, 0.001), 1))
                .stroke(
                    LinearGradient(
                        colors: [.orange, .pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .shadow(color: .black.opacity(0.1), radius: 6)

            TimelineView(.periodic(from: now, by: 60)) { context in
                let fraction = scrubProgress ?? fraction(for: context.date)

                if (fraction > 0.01 && fraction < 0.99) || scrubProgress != nil {
                    sunDisc(fraction: fraction, size: size)
                }

                if scrubProgress != nil {
                    timeBubble(fraction: fraction, at: sunPosition(fraction: fraction, size: size), width: size.width)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    /// The sun as a glass disc with a warm core — the same clear-glass recipe
    /// as the wind card's compass, no custom materials.
    private func sunDisc(fraction: CGFloat, size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 10, height: 10)
        }
        .frame(width: 26, height: 26)
        .glassEffect(.clear, in: .circle)
        .shadow(color: .orange.opacity(0.35), radius: 6)
        .position(sunPosition(fraction: fraction, size: size))
    }

    /// The scrubbed time floats centered above the horizon.
    private func timeBubble(fraction: CGFloat, at position: CGPoint, width: CGFloat) -> some View {
        let date = sunrise.addingTimeInterval(sunset.timeIntervalSince(sunrise) * fraction)

        return Text(formattedTime(date))
            .font(.getFont(type: .bold, size: 15))
            .foregroundStyle(.dayTitle)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .glassEffect(.regular.interactive(), in: .capsule)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: Horizon

    private var horizonRow: some View {
        HStack(alignment: .center) {
            timeLabel(icon: "sunrise.fill", tint: .orange, date: sunrise, title: "Sunrise")
            Spacer()
            if let dayLength {
                VStack(spacing: 1) {
                    Image(systemName: "sun.max")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.orange)
                    Text(dayLength)
                        .font(.getFont(type: .medium, size: 13))
                        .foregroundStyle(.daySubTitle)
                }
            }
            Spacer()
            timeLabel(icon: "sunset.fill", tint: .purple, date: sunset, title: "Sunset")
        }
    }

    private func timeLabel(icon: String, tint: Color, date: Date, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 1) {
                Text(formattedTime(date))
                    .font(.getFont(type: .bold, size: 17))
                    .foregroundStyle(.dayTitle)
                Text(title)
                    .font(.getFont(type: .medium, size: 12))
                    .foregroundStyle(.daySubTitle)
            }
        }
    }

    // MARK: Geometry

    /// A point on the arc, matching the `SunArc` shape (centred on the rect's
    /// bottom edge) for a 0…1 daylight fraction.
    private func sunPosition(fraction: CGFloat, size: CGSize) -> CGPoint {
        let angle = Angle.degrees(180 - Double(min(max(fraction, 0), 1) * 180)).radians
        let radius = SunArc.arcRadius(in: size)
        let center = CGPoint(x: size.width / 2, y: size.height)
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y - radius * sin(angle)
        )
    }

    // MARK: Scrub

    private func scrubGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard width > 0 else { return }
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)

                if !isScrubbing {
                    // Commit only on a clearly horizontal move so vertical
                    // drags belong to the scroll view around the card.
                    guard horizontal > 4, horizontal > vertical else { return }
                    isScrubbing = true
                    scrubStartFraction = displayedFraction
                    returnTask?.cancel()
                }

                let start = scrubStartFraction
                let moved = value.translation.width / width
                scrubProgress = min(max(start + moved, 0), 1)
            }
            .onEnded { _ in
                isScrubbing = false
                scrubStartFraction = 0
                beginReturn()
            }
    }

    /// When the finger lifts, the sun rides back home *along the arc*: the
    /// scrubbed fraction eases towards the current time with a smoothstep, so
    /// the marker, the daylight gradient and the house light all follow the
    /// same path instead of snapping.
    private func beginReturn() {
        guard let from = scrubProgress else {
            returnTask = nil
            return
        }

        let target = fraction(for: .now)
        let duration: TimeInterval = 0.7
        // Already home — nothing to animate.
        guard abs(from - target) > 0.001 else {
            var transaction = Transaction()
            withTransaction(transaction) {
                scrubProgress = nil
            }
            returnTask = nil
            return
        }

        returnTask = Task { @MainActor in
            let start = Date()
            while !Task.isCancelled {
                let t = min(Date().timeIntervalSince(start) / duration, 1)
                let eased = t * t * (3 - 2 * t) // smoothstep
                scrubProgress = from + (target - from) * CGFloat(eased)

                if t >= 1 { break }
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
            if !Task.isCancelled {
                var transaction = Transaction()
                withTransaction(transaction) {
                    scrubProgress = nil
                }
            }
            returnTask = nil
        }
    }

    // MARK: Time

    private func fraction(for date: Date) -> CGFloat {
        let total = sunset.timeIntervalSince(sunrise)
        guard total > 0 else { return 0 }

        if date < sunrise { return 0 }
        if date > sunset { return 1 }

        return CGFloat(date.timeIntervalSince(sunrise) / total)
    }

    private func formattedTime(_ date: Date) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .omitted)
            .hour(.defaultDigits(amPM: .abbreviated))
            .minute()
        style.timeZone = timeZone
        return date.formatted(style)
    }
}

/// A semicircle: the sun's path from the left horizon to the right. The
/// radius is capped by the rect's height so the arc's apex never rises into
/// the header above the track, whatever the card's aspect ratio.
private struct SunArc: Shape {
    static func arcRadius(in size: CGSize) -> CGFloat {
        // The apex of the semicircle is the radius itself, so never let it
        // exceed the track height (minus headroom) and the full half-width.
        min(size.width / 2 * 0.86, size.height * 0.86)
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: Self.arcRadius(in: rect.size),
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

#if DEBUG
#Preview {
    ZStack {
        LinearGradient(
            colors: [
                .init(hex: "#FFFCEF"),
                .init(hex: "#EAE2B2")
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            SunriseSunsetGraphView(
                sunrise: SunriseSunsetData.sample.sunrise,
                sunset: SunriseSunsetData.sample.sunset
            )
            SunriseSunsetGraphView(sunrise: nil, sunset: nil)
        }
        .padding()
    }
    .environmentObject(SettingsStore.dependency)
}
#endif
