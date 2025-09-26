    //
    //  MainView.swift
    //  Tacho_Mini_Code
    //
    //  Created by Juergen on 18.09.25.
    //

import SwiftUI
import Combine



    /// Berechnet den Winkel für die Nadel basierend auf der Geschwindigkeit
func angle(for speed: Double, maxSpeed: Double,
           start: Angle = .degrees(-210), end: Angle = .degrees(30)) -> Angle {
    let clamped = max(0, min(speed, maxSpeed))
    let span = end.degrees - start.degrees
    let rel = clamped / maxSpeed
    return .degrees(start.degrees + rel * span)
}

    /// Zeichnet Hintergrund, Skala, Zeiger und digitale Anzeige
struct GaugeBase: View {
    @Environment(\.colorScheme) private var colorScheme
    var speed: Double // Aktuelle Geschwindigkeit
    var maxSpeed: Double // Maximale Geschwindigkeit
    var gaugeStyleType: String // Typ des GaugeStyles

    var body: some View {
        let style = createGaugeStyle(for: gaugeStyleType, colorScheme: colorScheme)
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size * 0.48 // Radius des Tachos
            ZStack {
                Circle()
                    .fill(style.backgroundFill)
                    .overlay(
                        Circle().stroke(style.outerStroke, lineWidth: style.outerStrokeWidth)
                            .blur(radius: style.outerGlow)
                            .opacity(style.outerGlow > 0 ? 1 : 0)
                    )
                    // Farbige Ringe/Dekoration
                style.rings

                    // Skala und Ticks
                Canvas { ctx, sz in
                    let center = CGPoint(x: sz.width/2, y: sz.height/2) // Mittelpunkt des Tachos
                    let minTickLen = radius * 0.06 // Länge der kleinen Ticks
                    let majTickLen = radius * 0.12 // Länge der großen Ticks
                    let start = -210.0 * .pi/180 // Startwinkel in Radiant
                    let end   =  30.0 * .pi/180 // Endwinkel in Radiant
                    let totalMinor = Int(maxSpeed / 10) // Anzahl der kleinen Ticks
                    let totalMajor = Int(maxSpeed / 20) // Anzahl der großen Ticks

                        // Zeichnet kleine und große Ticks
                    for i in 0...totalMinor {
                        let t = Double(i) / Double(totalMinor)
                        let a = start + t * (end - start) // Winkel für den Tick
                        let isMajor = (i % (totalMinor / totalMajor) == 0) // Prüft, ob es ein großer Tick ist

                        let len = isMajor ? majTickLen : minTickLen
                        let p1 = CGPoint(x: center.x + (radius - len) * cos(a),
                                         y: center.y + (radius - len) * sin(a))
                        let p2 = CGPoint(x: center.x + radius * cos(a),
                                         y: center.y + radius * sin(a))
                        var path = Path()
                        path.move(to: p1)
                        path.addLine(to: p2)

                        ctx.stroke(path, with: .color(style.tickColor.opacity(1.0)), lineWidth: isMajor ? 3 : 2)
                    }
                        // Zeichnet große Ticks und Labels
                    let labelFont = Font.system(size: radius * 0.12, weight: .semibold, design: .rounded)

                        // Zeichnet kleine und große Ticks sowie Labels
                    for i in 0...totalMinor {
                        let t = Double(i) / Double(totalMinor)
                        let a = start + t * (end - start) // Winkel für den Tick
                        let isMajor = (i % (totalMinor / totalMajor) == 0) // Prüft, ob es ein großer Tick ist

                        let len = isMajor ? majTickLen : minTickLen
                        let p1 = CGPoint(x: center.x + (radius - len) * cos(a),
                                         y: center.y + (radius - len) * sin(a))
                        let p2 = CGPoint(x: center.x + radius * cos(a),
                                         y: center.y + radius * sin(a))
                        var path = Path()
                        path.move(to: p1)
                        path.addLine(to: p2)

                        ctx.stroke(path, with: .color(style.tickColor.opacity(1.0)), lineWidth: isMajor ? 3 : 2)

                            // Zeichnet Labels nur für große Ticks
                        if isMajor {
                            let value = i * 10
                            let labelR = radius - majTickLen - radius * 0.12
                            let lp = CGPoint(x: center.x + labelR * cos(a),
                                             y: center.y + labelR * sin(a))
                            let text = AttributedString(String(value), attributes: .init([
                                .font: labelFont,
                                .foregroundColor: style.labelColor
                            ]))
                            ctx.draw(Text(text), at: lp, anchor: .center)
                        }
                    }
                }
                .padding(style.canvasPadding)

                    // Digitale Geschwindigkeitsanzeige
                VStack(spacing: 0) {
                    Text("\(Int(speed.rounded()))")
                        .font(.system(size: radius * 0.45, weight: .bold, design: .rounded).monospacedDigit())
                        .kerning(-2)
                        .foregroundStyle(style.digitalForeground)

                    Text("km/h")
                        .font(.system(size: radius * 0.14, weight: .semibold, design: .rounded))
                        .foregroundStyle(style.digitalForeground)
                        .padding(.top, -radius*0.08)
                }
                .offset(y: -radius * 0.35)

                    // Zeiger des Tachos
                Needle(angle: angle(for: speed, maxSpeed: maxSpeed),
                       radius: radius,
                       thickness: style.needleThickness,
                       hubSize: style.hubSize)
                .fill(AnyShapeStyle(style.needleFill))
                .shadow(radius: style.needleShadow)
                Circle()
                    .fill(AnyShapeStyle(style.needleFill))
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
        var p = Path()
        p.move(to: tip)
        p.addLine(to: point(from: center, angle: angle.radians + .pi/2, dist: thickness))
        p.addLine(to: back)
        p.addLine(to: point(from: center, angle: angle.radians - .pi/2, dist: thickness))
        p.closeSubpath()
        return p
    }

        // Optimierung der Methode point
    private func point(from c: CGPoint, angle: CGFloat, dist: CGFloat) -> CGPoint {
        let dx = dist * cos(angle)
        let dy = dist * sin(angle)
        return CGPoint(x: c.x + dx, y: c.y + dy)
    }
}

    /// Styling
struct GaugeStyle {
    var backgroundFill: AnyShapeStyle {
        AnyShapeStyle(colorScheme == .dark ? Color.black : Color.white)
    }
    var outerStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.8) : Color.gray.opacity(0.8)
    }
    var tickColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color.gray.opacity(0.9)
    }
    var labelColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    var digitalForeground: any ShapeStyle {
        colorScheme == .dark ? Color.white : Color.primary
    }
    var hubStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color(UIColor.separator)
    }
    var outerStrokeWidth: CGFloat = 2
    var outerGlow: CGFloat = 10
    var needleFill: any ShapeStyle = LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom)
    var needleThickness: CGFloat = 7
    var hubSize: CGFloat = 22
    var needleShadow: CGFloat = 3
    var depthShadow: CGFloat = 8
    var canvasPadding: CGFloat = 10
    var rings: AnyView = AnyView(EmptyView())

    var colorScheme: ColorScheme

    init(
        colorScheme: ColorScheme,
        rings: AnyView = AnyView(EmptyView()),
        tickColor: Color = .gray,
        labelColor: Color = .primary,
        needleFill: any ShapeStyle = Color.red,
        needleThickness: CGFloat = 7,
        hubSize: CGFloat = 22,
        hubStroke: Color = .gray,
        outerStroke: Color = .gray,
        outerStrokeWidth: CGFloat = 2,
        outerGlow: CGFloat = 0,
        depthShadow: CGFloat = 8,
        canvasPadding: CGFloat = 10,
        backgroundFill: AnyShapeStyle = AnyShapeStyle(Color.white),
        digitalForeground: any ShapeStyle = Color.primary
    ) {
        self.colorScheme = colorScheme
        self.rings = rings
        self.needleFill = needleFill
        self.needleThickness = needleThickness
        self.hubSize = hubSize
        self.outerStrokeWidth = outerStrokeWidth
        self.outerGlow = outerGlow
        self.depthShadow = depthShadow
        self.canvasPadding = canvasPadding
    }
}

    /// Timer
struct TimerControlView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var remaining: Int
    @Binding var isRunning: Bool
    var elapsedTimes: [Int]
    var elapsedDistance: Double
    var totalDistance: Double
    var toggleStartPause: () -> Void
    var reset: () -> Void
    var saveElapsedTime: () -> Void
    var deleteElapsedTime: (Int) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(timeString(from: remaining))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(5)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Text(String(format: "Entfernung: %.2f km", totalDistance))
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            HStack(spacing: 20) {
                Button(action: toggleStartPause) {
                    Text(isRunning ? "Pause" : "Start")
                        .font(.headline)
                        .padding(10)
                        .background(isRunning ? Color.red : Color.green)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                }
                Button(action: reset) {
                    Text("Reset")
                        .font(.headline)
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                }
                Button(action: saveElapsedTime) {
                    Text("Elapsed")
                        .font(.headline)
                        .padding(10)
                        .background(Color.orange)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                }
            }
            LazyVStack(spacing: 10) {
                ForEach(elapsedTimes.indices, id: \.self) { index in
                    let time = elapsedTimes[index]
                    let previousTime = index > 0 ? elapsedTimes[index - 1] : 0
                    let difference = time - previousTime
                    let distance = elapsedDistance * (Double(difference) / Double(remaining))
                    HStack {
                        Text("Runde \(index + 1)")
                            .foregroundColor(.primary)
                            .fontWeight(.bold)
                        Text(timeString(from: time))
                            .foregroundColor(.primary)
                            .fontWeight(.regular)
                        Text("(+\(timeString(from: difference)))")
                            .foregroundColor(.secondary)
                            .fontWeight(.light)
                        Text(String(format: "%.2f km", distance))
                            .foregroundColor(.secondary)
                            .fontWeight(.light)
                        Spacer()
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .onTapGesture {
                                deleteElapsedTime(time)
                            }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
        .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGray6))
        .cornerRadius(15)
        .shadow(radius: 5)
    }

    private func timeString(from seconds: Int) -> String {
        let s = abs(seconds)
        let m = s / 60
        let r = s % 60
        return String(format: "%@%02d:%02d", seconds < 0 ? "-" : "", m, r)
    }
}

    /// Utility class for managing timers
class TimerManager: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var elapsedTime: Int = 0
    @Published var elapsedTimes: [Int] = []
    @Published var elapsedDistance: Double = 0.0
    @Published var totalDistance: Double = 0.0

    private var timer: Timer? = nil
    private var currentSpeed: Double = 0.0

    func startTimer(interval: TimeInterval = 1, action: @escaping () -> Void) {
        guard timer == nil else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.elapsedTime += 1
            let distanceIncrement = self.currentSpeed / 3600 // Geschwindigkeit in km/s
            self.elapsedDistance += distanceIncrement
            self.totalDistance += distanceIncrement // Aktualisiere die gesamte Entfernung
            action()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func resetTimer() {
        stopTimer()
        elapsedTime = 0
        elapsedDistance = 0.0
        totalDistance = 0.0
    }

    func updateSpeed(_ speed: Double) {
        currentSpeed = speed
    }

    func saveElapsedTime() {
        elapsedTimes.append(elapsedTime)
    }

    func deleteElapsedTime(_ time: Int) {
        if let index = elapsedTimes.firstIndex(of: time) {
            elapsedTimes.remove(at: index) // Löscht nur den ersten Eintrag
        }
    }
}

    /// Overlay
struct SpeedOverlay: View {
    @Environment(\.colorScheme) var colorScheme
    var speed: Double
    var maxSpeed: Double = 200
    var gaugeStyleType: String

    var body: some View {
        ZStack {

            GaugeBase(
                speed: speed,
                maxSpeed: maxSpeed,
                gaugeStyleType: gaugeStyleType
            )
        }
        .padding(8)
        .clipShape(Circle())
    }
}

    /// Funktion zur Erstellung eines gemeinsamen GaugeStyle
func createGaugeStyle(for type: String = "default", colorScheme: ColorScheme) ->
GaugeStyle {
    switch type {
        case "overlay":
            let startPoint = UnitPoint(x: 0.0, y: 0.0)
            let endPoint = UnitPoint(x: 1.0, y: 1.0)
            return GaugeStyle(
                colorScheme: colorScheme,
                rings: AnyView(
                    ZStack {
                        Circle().inset(by: 14)
                            .trim(from: 0.17, to: 0.437)
                            .stroke(Color.blue, lineWidth: 8)
                            .rotationEffect(.degrees(89))

                        Circle().inset(by: 14)
                            .trim(from: 0.437, to: 0.567)
                            .stroke(Color.green, lineWidth: 8)
                            .rotationEffect(.degrees(89))

                        Circle().inset(by: 14)
                            .trim(from: 0.567, to: 0.835)
                            .stroke(Color.red, lineWidth: 8)
                            .rotationEffect(.degrees(89))

                        Circle().inset(by: -4)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.8), Color.black.opacity(0.6)]),
                                    startPoint: startPoint,
                                    endPoint: endPoint
                                ),
                                lineWidth: 8
                            )

                        Circle().inset(by: 4)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.8), Color.black.opacity(0.6)]),
                                    startPoint: endPoint,
                                    endPoint: startPoint
                                ),
                                lineWidth: 8
                            )
                    }
                ),
                tickColor: colorScheme == .dark ? Color.white.opacity(0.85) : Color.gray.opacity(0.85),
                labelColor: colorScheme == .dark ? Color.white : Color.black,
                needleFill: LinearGradient(
                    colors: colorScheme == .dark ? [Color.white, Color.gray] : [Color.yellow, Color.orange],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            case "modern":
                // Neues modernes Design
            return GaugeStyle(
                colorScheme: colorScheme,
                rings: AnyView(
                    ZStack {
                        Circle().stroke(Color.gray, lineWidth: 2)
                        Circle().inset(by: 10)
                            .stroke(LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.orange]),
                                startPoint: .top,
                                endPoint: .bottom
                            ), lineWidth: 4)
                    }
                ),
                tickColor: Color.purple,
                labelColor: Color.orange,
                needleFill: LinearGradient(
                    colors: [Color.pink, Color.orange],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

        case "minimal":
                // Neues minimalistisches Design
            return GaugeStyle(
                colorScheme: colorScheme,
                rings: AnyView(EmptyView()),
                tickColor: Color.gray,
                labelColor: Color.primary,
                needleFill: Color.blue
            )


        default:
            return GaugeStyle(colorScheme: colorScheme)
    }
}


    /// Hauptansicht für diese Seite!
struct MainView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var speed: Double = 50
    @State private var sessionActive = false
    @State private var sessionTicker: Timer? = nil
    @State private var sessionSeconds: Int = 0
    @State private var maxSpeed: Double = 200
    @StateObject private var sessionTimer = TimerManager()
    @State private var gaugeStyleType: String = "default"

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                (colorScheme == .dark ? Color.black : Color.white)
                    .edgesIgnoringSafeArea(.all)
                ScrollView () {
                    VStack(spacing: 14) {
                        SpeedOverlay(
                            speed: speed,
                            maxSpeed: maxSpeed,
                            gaugeStyleType: gaugeStyleType
                        )
                        .frame(width: min(geometry.size.width, geometry.size.height) * 0.9,
                               height: min(geometry.size.width, geometry.size.height) * 0.9)
                        .padding(.top, 10)

                        Spacer()

                        TimerControlView(
                            remaining: $sessionTimer.elapsedTime,
                            isRunning: $sessionTimer.isRunning,
                            elapsedTimes: sessionTimer.elapsedTimes,
                            elapsedDistance: sessionTimer.elapsedDistance,
                            totalDistance: sessionTimer.totalDistance,
                            toggleStartPause: toggleCountdown,
                            reset: sessionTimer.resetTimer,
                            saveElapsedTime: sessionTimer.saveElapsedTime,
                            deleteElapsedTime: sessionTimer.deleteElapsedTime
                        )

                        Text("Speed: \(Int(speed)) km/h")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Slider(value: $speed, in: 0...maxSpeed, step: 1, onEditingChanged: { _ in
                            sessionTimer.updateSpeed(speed)
                        })
                        .accentColor(.blue)

                        HStack {
                            Button(action: {
                                gaugeStyleType = "default"
                            }) {
                                Text("Standard")
                                    .font(.headline)
                                    .padding(10)
                                    .background(gaugeStyleType == "default" ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }

                            Button(action: {
                                gaugeStyleType = "overlay"
                            }) {
                                Text("Overlay")
                                    .font(.headline)
                                    .padding(10)
                                    .background(gaugeStyleType == "overlay" ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }

                            Button(action: {
                                gaugeStyleType = "modern"
                            }) {
                                Text("Modern")
                                    .font(.headline)
                                    .padding(10)
                                    .background(gaugeStyleType == "modern" ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }

                            Button(action: {
                                gaugeStyleType = "minimal"
                            }) {
                                Text("Minimal")
                                    .font(.headline)
                                    .padding(10)
                                    .background(gaugeStyleType == "minimal" ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }


    private func toggleCountdown() {
        if sessionTimer.isRunning {
            sessionTimer.stopTimer()
        } else {
            sessionTimer.updateSpeed(speed)
            sessionTimer.startTimer {
            }
        }
    }
}

#Preview {
    MainView()
}
