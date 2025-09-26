    //
    //  GaugeView.swift
    //  Tacho_Mini
    //
    //  Created by Juergen on 26.09.25.
    //

import SwiftUI

    /// Berechnet den Winkel für die Nadel basierend auf der Geschwindigkeit
func angle(for speed: Double, maxSpeed: Double, start: Angle = .degrees(-210), end: Angle = .degrees(30)) -> Angle {
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
                style.rings

                Canvas { ctx, sz in
                    drawTicksAndLabels(ctx: ctx, sz: sz, radius: radius, style: style)
                }
                .padding(style.canvasPadding)

                VStack(spacing: 0) {
                    Text("\(Int(speed.rounded()))")
                        .font(.system(size: radius * 0.45, weight: .bold, design: .rounded).monospacedDigit())
                        .kerning(-2)
                        .foregroundStyle(style.digitalForeground)

                    Text("km/h")
                        .font(.system(size: radius * 0.14, weight: .semibold, design: .rounded))
                        .foregroundStyle(style.digitalForeground)
                        .padding(.top, -radius * 0.08)
                }
                .offset(y: -radius * 0.35)

                Needle(angle: angle(for: speed, maxSpeed: maxSpeed),
                       radius: radius,
                       thickness: style.needleThickness,
                       hubSize: style.hubSize)
                .fill(AnyShapeStyle(style.needleFill))
                .shadow(radius: style.needleShadow)
                Circle()
                    .fill(AnyShapeStyle(style.needleFill))
                    .frame(width: style.hubSize, height: style.hubSize)
                    .overlay(Circle().stroke(style.hubStroke, lineWidth: 0.5))
            }
            .compositingGroup()
            .shadow(radius: style.depthShadow)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func drawTicksAndLabels(ctx: GraphicsContext, sz: CGSize, radius: CGFloat, style: GaugeStyle) {
        let center = CGPoint(x: sz.width / 2, y: sz.height / 2)
        let minTickLen = radius * 0.06
        let majTickLen = radius * 0.12
        let start = -210.0 * .pi / 180
        let end = 30.0 * .pi / 180
        let totalMinor = Int(maxSpeed / 10)
        let totalMajor = Int(maxSpeed / 20)
        let labelFont = Font.system(size: radius * 0.12, weight: .semibold, design: .rounded)

        for i in 0...totalMinor {
            let t = Double(i) / Double(totalMinor)
            let a = start + t * (end - start)
            let isMajor = (i % (totalMinor / totalMajor) == 0)
            let len = isMajor ? majTickLen : minTickLen
            let p1 = CGPoint(x: center.x + (radius - len) * cos(a), y: center.y + (radius - len) * sin(a))
            let p2 = CGPoint(x: center.x + radius * cos(a), y: center.y + radius * sin(a))
            var path = Path()
            path.move(to: p1)
            path.addLine(to: p2)
            ctx.stroke(path, with: .color(style.tickColor.opacity(1.0)), lineWidth: isMajor ? 3 : 2)

            if isMajor {
                let value = i * 10
                let labelR = radius - majTickLen - radius * 0.12
                let lp = CGPoint(x: center.x + labelR * cos(a), y: center.y + labelR * sin(a))
                let text = AttributedString(String(value), attributes: .init([
                    .font: labelFont,
                    .foregroundColor: style.labelColor
                ]))
                ctx.draw(Text(text), at: lp, anchor: .center)
            }
        }
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
        p.addLine(to: point(from: center, angle: angle.radians + .pi / 2, dist: thickness))
        p.addLine(to: back)
        p.addLine(to: point(from: center, angle: angle.radians - .pi / 2, dist: thickness))
        p.closeSubpath()
        return p
    }

    private func point(from c: CGPoint, angle: CGFloat, dist: CGFloat) -> CGPoint {
        let dx = dist * cos(angle)
        let dy = dist * sin(angle)
        return CGPoint(x: c.x + dx, y: c.y + dy)
    }
}

    /// Funktion zur Erstellung eines gemeinsamen GaugeStyle
func createGaugeStyle(for type: String = "default", colorScheme: ColorScheme) -> GaugeStyle {
    let startPoint: UnitPoint = .top
    let endPoint: UnitPoint = .bottom

    switch type {
        case "overlay":
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
                tickColor: colorScheme == .dark ? Color.white.opacity(0.85) : Color.gray.opacity(0.85),
                labelColor: colorScheme == .dark ? Color.white : Color.black,
                needleFill: LinearGradient(
                    colors: colorScheme == .dark ? [Color.white, Color.gray] : [Color.yellow, Color.orange],
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
        case "modern":
            return GaugeStyle(
                colorScheme: colorScheme,
                rings: AnyView(
                    ZStack {
                        Circle().inset(by: 10)
                            .stroke(Color.gray, lineWidth: 6)
                            .opacity(0.3)
                    }
                ),
                tickColor: Color.blue,
                labelColor: Color.green,
                needleFill: Color.gray,
                needleThickness: 4,
                hubSize: 8,
                outerStroke: Color.blue,
                outerStrokeWidth: 3,
                outerGlow: 5,
                backgroundFill: AnyShapeStyle(colorScheme == .dark ? Color(red: 0.3, green: 0.4, blue: 0.3) : Color(red: 0.7, green: 0.8, blue: 0.7))
            )
        case "minimal":
            return GaugeStyle(
                colorScheme: colorScheme,
                rings: AnyView(
                    Circle().stroke(Color.gray, lineWidth: 2)
                ),
                tickColor: Color.gray,
                labelColor: Color.gray,
                needleFill: Color.gray,
                needleThickness: 3,
                hubSize: 10,
                outerStroke: Color.clear,
                outerStrokeWidth: 0,
                outerGlow: 0
            )
        default:
            return GaugeStyle(colorScheme: colorScheme)
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
