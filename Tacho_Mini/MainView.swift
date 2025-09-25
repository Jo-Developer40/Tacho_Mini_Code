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
    let clamped = max(0, min(speed, maxSpeed)) // Begrenzung der Geschwindigkeit
    let span = end.degrees - start.degrees // Gesamtwinkelspanne
    let rel = clamped / maxSpeed // Verhältnis der Geschwindigkeit zur Maximalgeschwindigkeit
    return .degrees(start.degrees + rel * span) // Berechneter Winkel
}

    /// Zeichnet Hintergrund, Skala, Zeiger und digitale Anzeige
struct GaugeBase: View {
    var speed: Double // Aktuelle Geschwindigkeit
    var maxSpeed: Double // Maximale Geschwindigkeit
    var style: GaugeStyle = createGaugeStyle()
    var isDarkMode: Bool // Darkmodus berücksichtigen

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size * 0.48 // Radius des Tachos
            ZStack {
                Circle()
                    .fill(isDarkMode ? AnyShapeStyle(Color.black) : AnyShapeStyle(style.backgroundFill))
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
                    let midTickLen = radius * 0.09 // Länge der mittleren Ticks
                    let majTickLen = radius * 0.12 // Länge der großen Ticks

                    let start = -210.0 * .pi/180 // Startwinkel in Radiant
                    let end   =  30.0 * .pi/180 // Endwinkel in Radiant
                    let totalMinor = Int(maxSpeed / 10) // Anzahl der kleinen Ticks
                    let totalMajor = Int(maxSpeed / 20) // Anzahl der großen Ticks
                                                        // Zeichnet kleine und mittlere Ticks
                    for i in 0...totalMinor {
                        let t = Double(i) / Double(totalMinor)
                        let a = start + t * (end - start) // Winkel für den Tick
                        let isMid = (i % 2 == 0) // Prüft, ob es ein mittlerer Tick ist
                        let len = isMid ? midTickLen : minTickLen
                        let p1 = CGPoint(x: center.x + (radius - len) * cos(a),
                                         y: center.y + (radius - len) * sin(a))
                        let p2 = CGPoint(x: center.x + radius * cos(a),
                                         y: center.y + radius * sin(a))
                        var path = Path()
                        path.move(to: p1); path.addLine(to: p2)

                        ctx.stroke(path, with: .color(isDarkMode ? Color.white.opacity(0.9) : style.tickColor.opacity(0.9)), lineWidth: 2)
                    }
                        // Zeichnet große Ticks und Labels
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
                        ctx.stroke(path, with: .color(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.9)), lineWidth: 3)

                            // Label für die großen Ticks
                        let value = j * 20
                        let labelR = radius - majTickLen - radius*0.12
                        let lp = CGPoint(x: center.x + labelR * cos(a),
                                         y: center.y + labelR * sin(a))
                        let text = AttributedString(String(value), attributes: .init([
                            .font: labelFont,
                            .foregroundColor: isDarkMode ? Color.white : style.labelColor
                        ]))
                        ctx.draw(Text(text), at: lp, anchor: .center)
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
        AnyShapeStyle(isDarkMode ? Color.black : Color.white)
    }
    var outerStroke: Color {
        isDarkMode ? Color.white.opacity(0.8) : Color.gray.opacity(0.8)
    }
    var tickColor: Color {
        isDarkMode ? Color.white.opacity(0.9) : Color.gray.opacity(0.9)
    }
    var labelColor: Color {
        isDarkMode ? Color.white : Color.primary
    }
    var subLabelColor: Color {
        isDarkMode ? Color.gray : Color.secondary
    }
    var digitalForeground: any ShapeStyle {
        isDarkMode ? Color.white : Color.primary
    }
    var hubFill: any ShapeStyle {
        isDarkMode ? Color.black.opacity(0.8) : Color(UIColor.systemGray6)
    }
    var hubStroke: Color {
        isDarkMode ? Color.white.opacity(0.6) : Color(UIColor.separator)
    }
    var outerStrokeWidth: CGFloat = 2
    var outerGlow: CGFloat = 10
    var digitalShadow: Color = Color(UIColor.systemGray)
    var digitalShadowRadius: CGFloat = 8
    var needleFill: any ShapeStyle = LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom)
    var needleThickness: CGFloat = 7
    var hubSize: CGFloat = 22
    var needleShadow: CGFloat = 3
    var depthShadow: CGFloat = 8
    var canvasPadding: CGFloat = 10

    public var isDarkMode: Bool

    init(isDarkMode: Bool) {
        self.isDarkMode = isDarkMode
    }
}

    /// Timer
struct TimerControlView: View {
    @Binding var remaining: Int
    @Binding var isRunning: Bool
    var elapsedTimes: [Int]
    var elapsedDistance: Double
    var totalDistance: Double
    var toggleStartPause: () -> Void
    var reset: () -> Void
    var saveElapsedTime: () -> Void
    var deleteElapsedTime: (Int) -> Void
    var isDarkMode: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(timeString(from: remaining))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(5)
                .foregroundColor(isDarkMode ? .white : .black)
            Text(String(format: "Entfernung: %.2f km", totalDistance))
                .font(.headline)
                .foregroundColor(isDarkMode ? .gray : .secondary)
            HStack(spacing: 20) {
                Button(action: toggleStartPause) {
                    Text(isRunning ? "Pause" : "Start")
                        .font(.headline)
                        .padding(10)
                        .background(isRunning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: reset) {
                    Text("Reset")
                        .font(.headline)
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: saveElapsedTime) {
                    Text("Elapsed")
                        .font(.headline)
                        .padding(10)
                        .background(Color.orange)
                        .foregroundColor(.white)
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
        .background(isDarkMode ? Color.black : Color(UIColor.systemGray6))
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

    /// Overlay mit einstellbarem Schattenwinkel
struct SpeedOverlay: View {
    var speed: Double
    var maxSpeed: Double = 200
    var shadowAngle: Double
    var isDarkMode: Bool
    var gaugeStyleType: String

    var body: some View {
        ZStack {
            let startPoint = UnitPoint(
                x: 0.5 + 0.5 * cos(shadowAngle * .pi / 180),
                y: 0.5 + 0.5 * sin(shadowAngle * .pi / 180)
            )
            let endPoint = UnitPoint(
                x: 0.5 - 0.5 * cos(shadowAngle * .pi / 180),
                y: 0.5 - 0.5 * sin(shadowAngle * .pi / 180)
            )

            GaugeBase(
                speed: speed,
                maxSpeed: maxSpeed,
                style: createGaugeStyle(
                    for: "overlay",
                    startPoint: startPoint,
                    endPoint: endPoint,
                    isDarkMode: isDarkMode
                ),
                isDarkMode: isDarkMode
            )
        }
        .padding(8)
        .clipShape(Circle())
    }
}

    /// Funktion zur Erstellung eines gemeinsamen GaugeStyle
func createGaugeStyle(for type: String = "default", isDarkMode: Bool = false) ->

 GaugeStyle {
    let commonNeedleFill = LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom)
     switch type {
         case "overlay":
             return GaugeStyle(isDarkMode: isDarkMode)
         default:
             return GaugeStyle(isDarkMode: isDarkMode)
     }
     /*
    switch type {
        case "overlay":
            return GaugeStyle(
                outerStroke: isDarkMode ? Color.white.opacity(0.9) : Color.gray.opacity(0.9),
                outerStrokeWidth: 10,
                outerGlow: 7,
                rings: AnyView(
                    ZStack {
                        Circle().inset(by: 14)
                            .trim(from: 0.17, to: 0.437)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .butt))
                            .rotationEffect(.degrees(89))

                        Circle().inset(by: 14)
                            .trim(from: 0.437, to: 0.567)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .butt))
                            .rotationEffect(.degrees(89))

                        Circle().inset(by: 14)
                            .trim(from: 0.567, to: 0.835)
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .butt))
                            .rotationEffect(.degrees(89))

                        Circle().inset(by: -4)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.9), Color.black.opacity(0.4)]),
                                    startPoint: startPoint,
                                    endPoint: endPoint
                                ),
                                lineWidth: 8
                            )

                        Circle().inset(by: 4)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.8), Color.black.opacity(0.5)]),
                                    startPoint: endPoint,
                                    endPoint: startPoint
                                ),
                                lineWidth: 8
                            )
                    }
                ),
                tickColor: .white.opacity(0.85),
                labelColor: .white.opacity(0.85),
                subLabelColor: .white.opacity(0.6),
                digitalShadow: Color.cyan.opacity(0.6),
                digitalShadowRadius: CGFloat(8),
                needleFill: commonNeedleFill,
                needleThickness: 7,
                hubFill: Color.black.opacity(0.8),
                hubStroke: .white.opacity(0.6),
                hubSize: 22,
                needleShadow: 3,
                depthShadow: 8,
                canvasPadding: 10
            )
        default:
            return GaugeStyle(
                outerStroke: isDarkMode ? Color.white.opacity(0.8) : Color.gray.opacity(0.8),
                needleFill: commonNeedleFill
            )
    }
 */
}


    /// Hauptansicht für diese Seite!
struct MainView: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var speed: Double = 50
    @State private var shadowAngle: Double = 240.0
    @State private var sessionActive = false
    @State private var sessionTicker: Timer? = nil
    @State private var sessionSeconds: Int = 0
    @State private var maxSpeed: Double = 200
    @StateObject private var sessionTimer = TimerManager()
    @State private var gaugeStyleType: String = "default"

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                (isDarkMode ? Color.black : Color.white)
                    .edgesIgnoringSafeArea(.all)

                ScrollView () {
                    VStack(spacing: 14) {
                        SpeedOverlay(
                            speed: speed,
                            maxSpeed: 200,
                            shadowAngle: shadowAngle,
                            isDarkMode: isDarkMode,
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
                            deleteElapsedTime: sessionTimer.deleteElapsedTime,
                            isDarkMode: isDarkMode
                        )

                        Text("Speed: \(Int(speed)) km/h")
                            .font(.headline)
                            .foregroundColor(isDarkMode ? .white : .black)
                        Slider(value: $speed, in: 0...maxSpeed, step: 1, onEditingChanged: { _ in
                            sessionTimer.updateSpeed(speed)
                        })
                        .accentColor(.blue)

                        Text("Shadow Angle: \(Int(shadowAngle))°")
                            .font(.headline)
                            .foregroundColor(isDarkMode ? .white : .black)
                        Slider(value: $shadowAngle, in: 0.0...360.0, step: 1.0)
                            .accentColor(.green)

                        HStack {
                            Button(action: {
                                isDarkMode.toggle()
                            }) {
                                Text(isDarkMode ? "Dark" : "Light")
                                    .font(.headline)
                                    .padding(10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)

                                Spacer()

                                Button(action: {
                                    gaugeStyleType = (gaugeStyleType == "default") ? "overlay" : "default"
                                }) {
                                    Text(gaugeStyleType == "default" ? "Overlay" : "Default")
                                        .font(.headline)
                                        .padding(10)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
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
