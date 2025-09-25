    //
    //  button_styles.swift
    //  Tacho_Mini_Code
    //
    //  Created by Juergen on 19.09.25.
    //

import SwiftUI

extension Button {
    func dynamicStyle(isHighlighted: Bool) -> some View {
        self
            .padding()
            .background(isHighlighted ? Color.accentColor : Color(UIColor.systemBackground))
            .foregroundColor(isHighlighted ? Color(UIColor.systemBackground) : Color(UIColor.label))
            .cornerRadius(10)
            .shadow(color: Color(UIColor.systemGray), radius: 5, x: 0, y: 2)
    }
}

struct ContentViewStyle: View {
    @State private var isScaled = false // State für Animation

    var body: some View {
        VStack(spacing: 40) {
            List {
                Label("Home", systemImage: "house")
                Label("Settings", systemImage: "gear")
                Label("Profile", systemImage: "person.circle")
                Button(action: {
                    print("Zurück gedrückt")
                }) {
                    Label("Zurück", systemImage: "arrow.uturn.backward")
                }
            }

            Image(systemName: "heart.fill")
                .scaleEffect(isScaled ? 1.5 : 1.0) // Dynamische Skalierung
                .foregroundColor(.red)
                .font(.largeTitle)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isScaled = hovering
                    }
                }

            Button(action: {
                print("Button tapped")
            }) {
                HStack {
                    Image(systemName: "play.circle")
                    Text("Start")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Button(action: {
                print("Button tapped")
            }) {
                Text("Start")
                    .font(.headline)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: {
                print("Button tapped")
            }) {
                HStack {
                    Image(systemName: "play.circle")
                    Text("Start")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }

            Button(action: {
                print("Button tapped")
            }) {
                Text("Tap Me")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .scaleEffect(1.2)
                    .animation(.easeInOut, value: true)
            }
            Button(action: {
                print("Button tapped")
            }) {
                Text("Start")
                    .font(.headline)
                    .padding()
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]),
                                       startPoint: .leading,
                                       endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: {
            }) {
                Text("Start")
                    .padding()
                    .background(Circle().fill(Color.green))
                    .foregroundColor(.white)
            }
        }
    }
}

extension Color {
    static var starrySky: Color {
        Color(
            UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                    case .dark:
                        return UIColor(patternImage: UIImage(named: "starry_sky") ?? UIImage())
                    default:
                        return UIColor.systemBackground
                }
            }
        )
    }
}

#Preview {
    ContentViewStyle()
}
