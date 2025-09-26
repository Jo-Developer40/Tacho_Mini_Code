    //
    //  MainView.swift
    //  Tacho_Mini_Code
    //
    //  Created by Juergen on 18.09.25.
    //

import SwiftUI

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
