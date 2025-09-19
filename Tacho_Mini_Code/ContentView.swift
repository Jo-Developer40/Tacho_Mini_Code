    //
    //  ContentView.swift
    //  Tacho_Mini_Code
    //
    //  Created by Juergen on 18.09.25.
    //

import SwiftUI
import Combine

    // MARK: - Demo Recorder (ersetze später durch dein echtes Objekt)
final class DemoRecorder: ObservableObject {
    func start() { print("Recorder.start()") }
    func stop()  { print("Recorder.stop()") }
}

    // MARK: - Gemeinsame Utilities
    /// Kartesischer Winkel: 0° oben, positiv im Uhrzeigersinn
func angle(for speed: Double, maxSpeed: Double,
           start: Angle = .degrees(-210), end: Angle = .degrees(30)) -> Angle {
    let clamped = max(0, min(speed, maxSpeed))
    let span = end.degrees - start.degrees
    let rel = clamped / maxSpeed
    return .degrees(start.degrees + rel * span)
}

    /// Ticks & Zeiger werden in diesem Basiselement gezeichnet; Styling wird injiziert
struct GaugeBase: View {
    var speed: Double
    var maxSpeed: Double
    var style: GaugeStyle

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size * 0.48
            ZStack {
                    // Hintergrund
                Circle()
                    .fill(AnyShapeStyle(style.backgroundFill))
                    .overlay(
                        Circle().stroke(style.outerStroke, lineWidth: style.outerStrokeWidth)
                            .blur(radius: style.outerGlow)
                            .opacity(style.outerGlow > 0 ? 1 : 0)
                    )

                    // farbige Ringe / Deko
                style.rings

                    // Skala + Ticks
                Canvas { ctx, sz in
                    let center = CGPoint(x: sz.width/2, y: sz.height/2)
                    let minTickLen = radius * 0.06
                    let midTickLen = radius * 0.09
                    let majTickLen = radius * 0.12

                    let start = -210.0 * .pi/180
                    let end   =  30.0 * .pi/180
                    let totalMinor = Int(maxSpeed / 10)   // 10er Schritte
                    let totalMajor = Int(maxSpeed / 20)   // 20er Schritte

                        // Minor/Mid Ticks
                    for i in 0...totalMinor {
                        let t = Double(i) / Double(totalMinor)
                        let a = start + t * (end - start)
                        let isMid = (i % 2 == 0)
                        let len = isMid ? midTickLen : minTickLen
                        let p1 = CGPoint(x: center.x + (radius - len) * cos(a),
                                         y: center.y + (radius - len) * sin(a))
                        let p2 = CGPoint(x: center.x + radius * cos(a),                                        y: center.y + radius * sin(a))
                        var path = Path()
                        path.move(to: p1); path.addLine(to: p2)
                        ctx.stroke(path, with: .color(style.tickColor.opacity(isMid ? 0.9 : 0.6)), lineWidth: isMid ? 2 : 1)
                    }

                        // Major Ticks + Labels (20er)
                    let labelFont = Font.system(size: radius * 0.12, weight: .semibold, design: .rounded)
                    for j in 0...totalMajor {
                        let t = Double(j) / Double(totalMajor)
                        let a = start + t * (end - start)
                        let p1 = CGPoint(x: center.x + (radius - majTickLen) * cos(a),
                                         y: center.y + (radius - majTickLen) * sin(a))
                        let p2 = CGPoint(x: center.x + radius * cos(a),
                                         y: center.y + radius * sin(a))
                        var path = Path()
                        path.move(to: p1); path.addLine(to: p2)
                        ctx.stroke(path, with: .color(style.tickColor), lineWidth: 3)

                            // Label
                        let value = j * 20
                        let labelR = radius - majTickLen - radius*0.12
                        let lp = CGPoint(x: center.x + labelR * cos(a),
                                         y: center.y + labelR * sin(a))

                        let text = AttributedString(String(value), attributes: .init([
                            .font: labelFont,
                            .foregroundColor: style.labelColor
                        ]))
                        ctx.draw(Text(text), at: lp, anchor: .center)
                    }
                }
                .padding(style.canvasPadding)

                    // Digitalanzeige
                VStack(spacing: 0) {
                    Text("\(Int(speed.rounded()))")
                        .font(.system(size: radius * 0.45, weight: .bold, design: .rounded).monospacedDigit())
                        .kerning(-2)
                        .foregroundStyle(style.digitalForeground)
                        .shadow(color: style.digitalShadow, radius: style.digitalShadowRadius, x: 0, y: 0)
                    Text("km/h")
                        .font(.system(size: radius * 0.14, weight: .semibold, design: .rounded))
                        .foregroundStyle(style.subLabelColor)
                        .padding(.top, -radius*0.08)
                }
                .offset(y: -radius * 0.35)

                    // Zeiger
                Needle(angle: angle(for: speed, maxSpeed: maxSpeed),
                       radius: radius,
                       thickness: style.needleThickness,
                       hubSize: style.hubSize)
                .fill(AnyShapeStyle(style.needleFill))
                .shadow(radius: style.needleShadow)

                    // Center Hub
                Circle()
                    .fill(AnyShapeStyle(style.hubFill))
                    .frame(width: style.hubSize, height: style.hubSize)
                    .overlay(Circle().stroke(style.hubStroke, lineWidth: 2))
            }
            .compositingGroup()
            .shadow(radius: style.depthShadow)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

    /// Nadel
struct Needle: Shape {
    var angle: Angle
    var radius: CGFloat
    var thickness: CGFloat
    var hubSize: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = radius - 6
        let tip = CGPoint(
            x: center.x + r * CGFloat(cos(angle.radians)),
            y: center.y + r * CGFloat(sin(angle.radians))
        )
        let back = CGPoint(
            x: center.x + (hubSize * 0.4) * CGFloat(cos(angle.radians + .pi)),
            y: center.y + (hubSize * 0.4) * CGFloat(sin(angle.radians + .pi))
        )
            // schlanke Raute
        var p = Path()
        p.move(to: tip)
        p.addLine(to: point(from: center, angle: angle.radians + .pi/2, dist: thickness))
        p.addLine(to: back)
        p.addLine(to: point(from: center, angle: angle.radians - .pi/2, dist: thickness))
        p.closeSubpath()
        return p
    }

    private func point(from c: CGPoint, angle: CGFloat, dist: CGFloat) -> CGPoint {
        CGPoint(x: c.x + dist * cos(angle), y: c.y + dist * sin(angle))
    }
}

    /// Styling
struct GaugeStyle {
    var backgroundFill: any ShapeStyle
    var outerStroke: Color
    var outerStrokeWidth: CGFloat = 2
    var outerGlow: CGFloat = 0
    var rings: AnyView = AnyView(EmptyView())
    var tickColor: Color
    var labelColor: Color
    var subLabelColor: Color
    var digitalForeground: any ShapeStyle
    var digitalShadow: Color = .clear
    var digitalShadowRadius: CGFloat = 0
    var needleFill: any ShapeStyle
    var needleThickness: CGFloat = 6
    var hubFill: any ShapeStyle
    var hubStroke: Color
    var hubSize: CGFloat = 22
    var needleShadow: CGFloat = 0
    var depthShadow: CGFloat = 0
    var canvasPadding: CGFloat = 12
}

    /// Linker Split-Button & rechter Countdown
struct SplitRecordButton: View {
    @ObservedObject var recorder: DemoRecorder
    @Binding var sessionActive: Bool
    var startTimer: () -> Void
    var stopTimer: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button {
                guard !sessionActive else { return }
                sessionActive = true
                recorder.start()
                startTimer()
            } label: {
                Label("Start", systemImage: "record.circle")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button(role: .destructive) {
                guard sessionActive else { return }
                sessionActive = false
                recorder.stop()
                stopTimer()
            } label: {
                Label("Stop", systemImage: "stop.circle")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

    /// Rechter Countdown
struct CountdownControls: View {
    @Binding var remaining: Int
    @Binding var isRunning: Bool
    var toggleStartPause: () -> Void
    var reset: () -> Void
    var addMinute: (Int) -> Void
    var synchronize: () -> Void

    var body: some View {
        VStack(spacing: 10) {

                /// Anzeige Zähler
            Text(timeString(from: remaining))
                .monospacedDigit()
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))


                // Minuten +/-
            HStack(spacing: 8) {
                Button { addMinute(-1) } label: {
                    Label("", systemImage: "minus.circle")
                        .frame(minWidth: 20, minHeight: 20)
                }
                .buttonStyle(.bordered)

                Button { addMinute(+1) } label: {
                    Label("", systemImage: "plus.circle")
                        .frame(minWidth: 20, minHeight: 20)
                }
                .buttonStyle(.bordered)
            }

                // Start/Pause/Stop
            Button(action: {
                if remaining > 0 {
                    toggleStartPause()
                } else {
                    reset()
                }
            }) {
                Label(
                    remaining > 0 ? (isRunning ? "Pause" : "Start") : "Reset",
                    systemImage: remaining > 0 ? (isRunning ? "pause.fill" : "play.fill") : "arrow.counterclockwise"
                )
                .frame(minWidth: 80, minHeight: 20)
                .font(.headline)
                .padding()
                .background(remaining > 0 ? (isRunning ? Color.orange : Color.green) : Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)

            }
            .simultaneousGesture(LongPressGesture(minimumDuration: 2).onEnded { _ in
                reset()
            })

            Button(action: {
                synchronize()
            }) {
                Label("Sync", systemImage: "arrow.clockwise")
                    .frame(minWidth: 80, minHeight: 20)
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    private func timeString(from seconds: Int) -> String {
        let s = abs(seconds)
        let m = s / 60
        let r = s % 60
        return String(format: "%@%02d:%02d", seconds < 0 ? "-" : "", m, r)
    }
}

    // Entwurf A: Glassmorphism
struct SpeedOverlayA: View {
    var speed: Double
    var maxSpeed: Double = 240

        // Services & State
    @StateObject private var recorder = DemoRecorder()
    @State private var sessionActive = false
    @State private var sessionTicker: Timer?
    @State private var sessionSeconds: Int = 0

    @State private var countdown: Int = 0
    @State private var isCountdownRunning = false
    @State private var countdownTimer: Timer?

    private var style: GaugeStyle {
        GaugeStyle(
            backgroundFill: AngularGradient(gradient: Gradient(colors: [
                Color.black.opacity(0.65),
                Color.black.opacity(0.75),
                Color.black.opacity(0.65)
            ]), center: .center),
            outerStroke: Color.white.opacity(0.25),
            outerStrokeWidth: 2,
            outerGlow: 10,
            rings: AnyView(
                ZStack {
                    Circle().inset(by: 14)
                        .trim(from: 0.15, to: 0.85)
                        .stroke(AngularGradient(colors: [Color.cyan, Color.blue, Color.cyan],
                                                center: .center),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .opacity(0.35)

                    Circle().inset(by: 28)
                        .trim(from: 0.15, to: 0.85)
                        .stroke(Color.white.opacity(0.08), lineWidth: 16)
                        .rotationEffect(.degrees(-90))
                }
            ),
            tickColor: .white.opacity(0.85),
            labelColor: .white.opacity(0.85),
            subLabelColor: .white.opacity(0.6),
            digitalForeground: LinearGradient(colors: [Color.white, Color.white.opacity(0.9)],
                                              startPoint: .top, endPoint: .bottom),
            digitalShadow: Color.cyan.opacity(0.6),
            digitalShadowRadius: 8,
            needleFill: LinearGradient(colors: [Color.yellow, Color.orange],
                                       startPoint: .top, endPoint: .bottom),
            needleThickness: 7,
            hubFill: Color.black.opacity(0.8),
            hubStroke: .white.opacity(0.6),
            hubSize: 22,
            needleShadow: 3,
            depthShadow: 8,
            canvasPadding: 10
        )
    }

    var body: some View {
        ZStack {
            GaugeBase(speed: speed, maxSpeed: maxSpeed, style: style)

                // Linker Bereich – geteilter Button
            /*
             VStack {
             SplitRecordButton(recorder: recorder,
             sessionActive: $sessionActive,
             startTimer: startSessionTimer,
             stopTimer: stopSessionTimer)
             Text(sessionActive ? "REC \(format(sessionSeconds))" : "Bereit")
             .font(.footnote.monospacedDigit())
             .foregroundStyle(Color.white.opacity(0.8))
             }
             .frame(maxWidth: .infinity, alignment: .leading)
             .padding(.leading, 24)
             .padding(.vertical, 24)
             .allowsHitTesting(true)
             .blendMode(.plusLighter)
             .frame(maxHeight: .infinity)

             */
                // Rechter Bereich – Countdown
            VStack {
                CountdownControls(
                    remaining: $countdown,
                    isRunning: $isCountdownRunning,
                    toggleStartPause: startPauseCountdown,
                    reset: stopCountdown,
                    addMinute: { add in countdown = max(0, countdown + 60 * add) },
                    synchronize: synchronizeCountdown
                )
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 24)
            .padding(.vertical, 24)
        }
        .padding(8)
        .background(
            Circle().fill(
                RadialGradient(colors: [Color.black.opacity(0.85), Color.black],
                               center: .center, startRadius: 0, endRadius: 400)
            )
        )
        .clipShape(Circle())
    }

        // MARK: Session Timer
    private func startSessionTimer() {
        sessionTicker?.invalidate()
        sessionTicker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            sessionSeconds += 1
        }
    }
    private func stopSessionTimer() {
        sessionTicker?.invalidate()
        sessionTicker = nil
        sessionSeconds = 0
    }
    private func format(_ s: Int) -> String {
        String(format: "%02d:%02d", s/60, s%60)
    }

        // MARK: Countdown
    private func startPauseCountdown() {
        if isCountdownRunning {
            countdownTimer?.invalidate()
            isCountdownRunning = false
            return
        }
        isCountdownRunning = true
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                countdownTimer?.invalidate()
                isCountdownRunning = false
            }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        isCountdownRunning = false
        countdown = -300 // Setzt den Countdown auf -05:00 zurück
    }

    private func synchronizeCountdown() {
        let remainder = countdown % 60
        if remainder != 0 {
            countdown -= remainder // Setzt auf die vorhergehende volle Minute
        }
    }

    private func addMinute(_ minutes: Int) {
        if minutes > 0 {
            countdown = min(0, countdown + (minutes * 60)) // Erhöht nur bis 00:00
        } else {
            countdown += (minutes * 60) // Reduziert in den negativen Bereich
        }
    }
}

    /// Slider zur Geschwindigkeitsanpassung
struct SpeedSlider: View {
    @Binding var speed: Double
    var maxSpeed: Double

    var body: some View {
        VStack {
            Text("Speed: \(Int(speed)) km/h")
                .font(.headline)

            Slider(value: $speed, in: 0...maxSpeed, step: 1)
                .accentColor(.blue)
        }
        .padding()
    }
}

struct ContentView: View {
    @StateObject private var recorder = DemoRecorder()
    @State private var isRecording = false
    @State private var speed: Double = 50 // Initial speed value

    var body: some View {
        ZStack {
                // Tacho-Ansicht
            SpeedOverlayA(speed: speed, maxSpeed: 200)

            VStack {
                Spacer()

                    // Start/Stop Button
                Button(action: {
                    if isRecording {
                        recorder.stop()
                        isRecording = false
                    } else {
                        recorder.start()
                        isRecording = true
                    }
                }) {
                    Label(isRecording ? "Stop" : "Start", systemImage: isRecording ? "stop.circle" : "record.circle")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .font(.headline)
                        .padding()
                        .background(isRecording ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)

                    // Geschwindigkeitseinstellung Slider
                SpeedSlider(speed: $speed, maxSpeed: 200)
                    .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    ContentView()
}
