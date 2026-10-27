import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum TastyTheme {
    static let paper = adaptive(
        light: (0.957, 0.945, 0.910),
        dark: (0.063, 0.086, 0.082)
    )

    static let raisedPaper = adaptive(
        light: (1.000, 1.000, 1.000),
        dark: (0.102, 0.133, 0.122)
    )

    static let ink = adaptive(
        light: (0.125, 0.149, 0.141),
        dark: (0.953, 0.941, 0.906)
    )

    static let secondaryInk = adaptive(
        light: (0.361, 0.384, 0.369),
        dark: (0.714, 0.737, 0.714)
    )

    static let actionFill = adaptive(
        light: (0.612, 0.243, 0.145),
        dark: (0.910, 0.506, 0.384)
    )

    static let actionForeground = adaptive(
        light: (1.000, 1.000, 1.000),
        dark: (0.063, 0.086, 0.082)
    )

    static let mapPoint = adaptive(
        light: (0.890, 0.635, 0.231),
        dark: (0.941, 0.710, 0.322)
    )

    static let mapPointForeground = adaptive(
        light: (0.125, 0.094, 0.055),
        dark: (0.125, 0.094, 0.055)
    )

    static let danger = adaptive(
        light: (0.612, 0.243, 0.145),
        dark: (0.910, 0.506, 0.384)
    )

    static let ratingYellow = adaptive(
        light: (0.949, 0.718, 0.020),
        dark: (1.000, 0.824, 0.290)
    )

    static let support = adaptive(
        light: (0.208, 0.420, 0.400),
        dark: (0.486, 0.722, 0.682)
    )

    static let subduedFill = adaptive(
        light: (0.910, 0.890, 0.843),
        dark: (0.145, 0.161, 0.141)
    )

    static let hairline = adaptive(
        light: (0.851, 0.847, 0.816),
        dark: (0.212, 0.255, 0.243)
    )

    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

#if os(macOS)
    private static func adaptive(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat)
    ) -> Color {
        let color = NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let value = isDark ? dark : light
            return NSColor(
                srgbRed: value.0,
                green: value.1,
                blue: value.2,
                alpha: 1
            )
        }
        return Color(nsColor: color)
    }
#else
    private static func adaptive(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(
            uiColor: UIColor { traits in
                let value = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(
                    red: value.0,
                    green: value.1,
                    blue: value.2,
                    alpha: 1
                )
            }
        )
    }
#endif
}

struct PaperBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let ink = TastyTheme.actionFill.opacity(0.12)
                let echo = TastyTheme.support.opacity(0.10)

                for index in 0..<6 {
                    let inset = CGFloat(index) * 18
                    var path = Path()
                    path.move(
                        to: CGPoint(
                            x: size.width * 0.46 + inset,
                            y: -30 + inset
                        )
                    )
                    path.addCurve(
                        to: CGPoint(
                            x: size.width + 50,
                            y: size.height * 0.30 + inset
                        ),
                        control1: CGPoint(
                            x: size.width * 0.64,
                            y: size.height * 0.16 - inset
                        ),
                        control2: CGPoint(
                            x: size.width * 0.90,
                            y: size.height * 0.04 + inset
                        )
                    )
                    context.stroke(
                        path,
                        with: .color(index.isMultiple(of: 2) ? ink : echo),
                        style: StrokeStyle(
                            lineWidth: 1.2,
                            lineCap: .round,
                            dash: [7, 8]
                        )
                    )
                }

                let marker = CGRect(
                    x: size.width * 0.12,
                    y: size.height * 0.80,
                    width: min(size.width * 0.34, 240),
                    height: 1
                )
                context.fill(
                    Path(marker),
                    with: .color(TastyTheme.actionFill.opacity(0.35))
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .allowsHitTesting(false)
        }
    }
}

struct TastyCard: ViewModifier {
    var padding: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(TastyTheme.raisedPaper)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(TastyTheme.hairline.opacity(0.75), lineWidth: 1)
            }
            .shadow(
                color: TastyTheme.ink.opacity(0.08),
                radius: 24,
                x: 0,
                y: 12
            )
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TastyTheme.label(15))
            .foregroundStyle(
                isEnabled ? TastyTheme.actionForeground : TastyTheme.secondaryInk
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                isEnabled
                    ? (
                        configuration.isPressed
                            ? TastyTheme.actionFill.opacity(0.82)
                            : TastyTheme.actionFill
                    )
                    : TastyTheme.secondaryInk.opacity(0.12)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct TastyMark: View {
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(TastyTheme.actionFill)
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(TastyTheme.actionForeground)
                .offset(y: -size * 0.02)
            Image(systemName: "fork.knife")
                .font(.system(size: size * 0.17, weight: .bold))
                .foregroundStyle(TastyTheme.actionForeground)
                .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
