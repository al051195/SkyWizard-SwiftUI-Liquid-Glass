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
        VStack(alignment: .leading, spacing: 16) {
            headerView

            if let sunrise, let sunset, sunset > sunrise {
                SunPathGraph(sunrise: sunrise, sunset: sunset, timeZone: timeZone, scrubProgress: $scrubProgress)
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
    var headerView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Sunrise & Sunset")
                    .font(.getFont(type: .bold, size: 19))
            }

            Spacer(minLength: 8)

            if let dayLength {
                Text(dayLength)
                    .font(.getFont(type: .medium, size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
        }
        .foregroundStyle(.primary)
    }

    var unavailableView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "cloud.slash")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Sunrise & sunset times are not available for this forecast.")
                .font(.getFont(type: .medium, size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .center)
        .multilineTextAlignment(.center)
    }
}

private struct SunPathGraph: View {
    let sunrise: Date
    let sunset: Date
    let timeZone: TimeZone
    @Binding var scrubProgress: CGFloat?

    @State private var now = Date()
    @State private var isScrubbing = false

    private var displayedFraction: CGFloat {
        scrubProgress ?? fraction(for: now)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                GeometryReader { proxy in
                    pathLayer(in: proxy.size)
                        .contentShape(Rectangle())
                        .simultaneousGesture(scrubGesture(width: proxy.size.width))
                }
                .frame(height: 132)
            }

            hourRuler

            HStack {
                timeLabel(icon: "sunrise.fill", tint: .orange, date: sunrise, title: "Sunrise", alignment: .leading)
                Spacer()
                timeLabel(icon: "sunset.fill", tint: .purple, date: sunset, title: "Sunset", alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            now = .now
        }
    }

    private func pathLayer(in size: CGSize) -> some View {
        let height = size.height
        let baselineY = height * 0.86

        return ZStack {
            SunPathCurve(baselineY: baselineY, progress: 1.0)
                .stroke(
                    LinearGradient(
                        colors: [.orange.opacity(0.5), .purple.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [6, 5])
                )

            SunPathCurve(baselineY: baselineY, progress: displayedFraction)
                .stroke(
                    LinearGradient(
                        colors: [.orange, .pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )

            TimelineView(.periodic(from: now, by: 60)) { context in
                let fraction = scrubProgress ?? fraction(for: context.date)
                let position = sunPosition(
                    on: SunPathCurve(baselineY: baselineY, progress: 1.0),
                    at: fraction,
                    in: size
                )

                if (fraction > 0.01 && fraction < 0.99) || scrubProgress != nil {
                    sunMarker(position: position)
                }

                if scrubProgress != nil, let fraction = scrubProgress {
                    timeBubble(at: fraction, position: position, in: size)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func scrubGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard width > 0 else { return }
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)

                if !isScrubbing {
                    guard horizontal > 3, horizontal >= vertical else { return }
                    isScrubbing = true
                }

                scrubProgress = min(max(value.location.x / width, 0), 1)
            }
            .onEnded { _ in
                isScrubbing = false
                scrubProgress = nil
            }
    }

    private var hourRuler: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .top) {
                Capsule()
                    .fill(Color.primary.opacity(0.16))
                    .frame(height: 2)
                    .padding(.horizontal, 8)
                    .padding(.top, 20)

                ForEach(0..<5, id: \.self) { index in
                    let fraction = CGFloat(index) / 4
                    Text(rulerTime(at: fraction))
                        .font(.getFont(type: .medium, size: 10))
                        .foregroundStyle(.secondary)
                        .position(x: 8 + (width - 16) * fraction, y: 7)
                }

                Rectangle()
                    .fill(.orange)
                    .frame(width: 3, height: 12)
                    .clipShape(Capsule())
                    .shadow(color: .orange.opacity(0.7), radius: 4)
                    .position(x: 8 + (width - 16) * displayedFraction, y: 21)
            }
            .frame(width: width)
        }
        .frame(height: 28)
    }

    private func sunMarker(position: CGPoint) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.orange, .yellow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 18, height: 18)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.85), lineWidth: 2)
            }
            .shadow(color: .orange.opacity(0.65), radius: 8)
            .position(position)
    }

    private func timeBubble(at fraction: CGFloat, position: CGPoint, in size: CGSize) -> some View {
        let date = sunrise.addingTimeInterval(sunset.timeIntervalSince(sunrise) * fraction)
        let bubbleX = min(max(position.x, 38), size.width - 38)

        return Text(formattedTime(date))
            .font(.getFont(type: .bold, size: 15))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .glassEffect(.clear.interactive(), in: .capsule)
            .shadow(color: .black.opacity(0.15), radius: 6)
            .position(x: bubbleX, y: 16)
    }

    private func fraction(for date: Date) -> CGFloat {
        let total = sunset.timeIntervalSince(sunrise)
        guard total > 0 else { return 0 }

        if date < sunrise { return 0 }
        if date > sunset { return 1 }

        return CGFloat(date.timeIntervalSince(sunrise) / total)
    }

    private func sunPosition(on curve: SunPathCurve, at fraction: CGFloat, in size: CGSize) -> CGPoint {
        let path = curve.path(in: CGRect(origin: .zero, size: size))
        return path.trimmedPath(from: 0, to: min(max(fraction, 0), 1))
            .currentPoint ?? CGPoint(x: 0, y: curve.baselineY)
    }

    private func rulerTime(at fraction: CGFloat) -> String {
        let date = sunrise.addingTimeInterval(sunset.timeIntervalSince(sunrise) * fraction)
        return formattedTime(date, omittingAMPM: true)
    }

    private func formattedTime(_ date: Date, omittingAMPM: Bool = false) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .omitted)
            .hour(omittingAMPM ? .defaultDigits(amPM: .omitted) : .defaultDigits(amPM: .abbreviated))
            .minute()
        style.timeZone = timeZone
        return date.formatted(style)
    }

    private func timeLabel(icon: String, tint: Color, date: Date, title: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                Text(formattedTime(date))
                    .font(.getFont(type: .bold, size: 18))
            }
            Text(title)
                .font(.getFont(type: .medium, size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

private struct SunPathCurve: Shape {
    var baselineY: CGFloat
    var progress: CGFloat

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let left = CGPoint(x: 0, y: baselineY)
        let right = CGPoint(x: width, y: baselineY)
        let control = CGPoint(x: width / 2, y: baselineY - (height * 0.92))

        var path = Path()
        if progress <= 0 {
            return path
        }

        path.move(to: left)
        path.addQuadCurve(to: right, control: control)
        let trimmed = path.trimmedPath(from: 0, to: min(max(progress, 0), 1))
        return trimmed
    }

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
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
