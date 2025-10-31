import SwiftUI

// MARK: - AudioText Design System
// Neumorphic + Teenage Engineering Aesthetic
// Soft, tactile depth with clean minimalism

/// Main design system namespace
enum DesignSystem {

    // MARK: - Colors (Neumorphic + Teenage Engineering)

    enum Colors {
        // MARK: Base Colors (Smart Home Reference - Very Light)
        static let background = Color(red: 0.91, green: 0.925, blue: 0.94) // #E8ECF0 light blue-gray
        static let surface = Color(red: 0.91, green: 0.925, blue: 0.94) // Same as background
        static let surfaceElevated = Color(red: 0.93, green: 0.945, blue: 0.96) // Barely lighter

        // MARK: Neumorphic Shadow Colors (Very Soft - Reference Style)
        static let shadowDark = Color(hex: "B8BCC4").opacity(0.15) // Very subtle gray shadow
        static let shadowLight = Color.white.opacity(0.9) // Strong white highlight
        static let highlightLight = Color.white.opacity(0.95) // Very bright highlight

        // MARK: Apple System Colors (Vibrant, standard iOS colors)
        static let accentBlue = Color.blue // Apple blue
        static let accentCyan = Color.cyan // Apple cyan
        static let accentOrange = Color.orange // Apple orange
        static let accentPink = Color.pink // Apple pink
        static let accentGreen = Color.green // Apple green
        static let accentPurple = Color.purple // Apple purple
        static let accentYellow = Color.yellow // Apple yellow
        static let accentRed = Color.red // Apple red

        // MARK: Functional Colors (Apple system colors)
        static let recording = Color.red // Red for recording
        static let success = Color.green // Green for success
        static let warning = Color.orange // Orange for warning
        static let error = Color.red // Red for error

        // MARK: Text Colors (app-tracker-swift exact)
        static let textPrimary = Color(red: 0.2, green: 0.2, blue: 0.3) // Headers, main body
        static let textSecondary = Color(red: 0.5, green: 0.5, blue: 0.6) // Subtitles, descriptions
        static let textTertiary = Color(red: 0.7, green: 0.7, blue: 0.8) // Disabled states
        static let textDisabled = Color(red: 0.8, green: 0.8, blue: 0.85) // Very subtle

        // MARK: Interactive States
        static let pressed = Color.black.opacity(0.2) // Pressed state overlay
        static let hover = Color.white.opacity(0.03) // Hover state overlay
        static let surfaceDepressed = Color(red: 0.88, green: 0.90, blue: 0.92) // Slightly darker for pressed state

        // MARK: Gradients (Subtle, for depth)
        static let surfaceGradient = LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // MARK: Gradients (app-tracker-swift style)

        // Neumorphic buttons use background color
        static let buttonGradient = LinearGradient(
            colors: [background, background],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Primary action gradient (Blue → Cyan)
        static let primaryGradient = LinearGradient(
            colors: [accentBlue, accentCyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Recording gradient (Red → Orange)
        static let recordingGradient = LinearGradient(
            colors: [recording, accentOrange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Legacy compatibility
        static let accentGradient = primaryGradient
    }

    // MARK: - Typography (Clean, Swiss-style like Teenage Engineering)

    enum Typography {
        // MARK: Display
        static let displayLarge = Font.system(size: 48, weight: .light, design: .default)
        static let displayMedium = Font.system(size: 36, weight: .light, design: .default)

        // MARK: Headline
        static let headlineLarge = Font.system(size: 28, weight: .medium, design: .default)
        static let headlineMedium = Font.system(size: 24, weight: .medium, design: .default)
        static let headlineSmall = Font.system(size: 20, weight: .medium, design: .default)

        // MARK: Title
        static let titleLarge = Font.system(size: 20, weight: .semibold, design: .default)
        static let titleMedium = Font.system(size: 18, weight: .semibold, design: .default)
        static let titleSmall = Font.system(size: 16, weight: .semibold, design: .default)

        // MARK: Body
        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

        // MARK: Caption
        static let captionLarge = Font.system(size: 12, weight: .regular, design: .default)
        static let captionMedium = Font.system(size: 11, weight: .regular, design: .default)

        // MARK: Monospace (Technical readouts)
        static let monoLarge = Font.system(size: 20, weight: .regular, design: .monospaced)
        static let monoMedium = Font.system(size: 15, weight: .regular, design: .monospaced)
        static let monoSmall = Font.system(size: 13, weight: .regular, design: .monospaced)
    }

    // MARK: - Spacing (8pt grid - Swiss design)

    enum Spacing {
        static let xxxSmall: CGFloat = 2
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 40
        static let xxxLarge: CGFloat = 48

        // Semantic (More generous from reference)
        static let cardPadding: CGFloat = 28 // Increased from 24
        static let elementSpacing: CGFloat = 20 // Increased from 16
        static let sectionSpacing: CGFloat = 40 // Increased from 32
        static let breathingRoom: CGFloat = 12 // New - minimum space around interactive elements
    }

    // MARK: - Corner Radius (Larger, softer - refined from reference)

    enum CornerRadius {
        static let small: CGFloat = 14  // Increased from 12
        static let medium: CGFloat = 18 // Increased from 16
        static let large: CGFloat = 24  // Increased from 20
        static let xLarge: CGFloat = 28 // Increased from 24
        static let xxLarge: CGFloat = 32 // New - for hero elements
        static let circular: CGFloat = 9999

        // Semantic
        static let button = medium // 18
        static let card = large // 24
        static let control = small // 14
    }

    // MARK: - Neumorphic Shadows (The key to the aesthetic!)

    enum NeumorphicShadow {
        // MARK: Small (Toggles, Small Buttons) - Reference Style (Very Soft)
        static func small() -> (light: (Color, CGFloat, CGFloat, CGFloat), dark: (Color, CGFloat, CGFloat, CGFloat)) {
            let light = (Colors.shadowLight, CGFloat(8), CGFloat(-3), CGFloat(-3))
            let dark = (Colors.shadowDark, CGFloat(10), CGFloat(4), CGFloat(4))
            return (light, dark)
        }

        // MARK: Medium (Cards, Panels, Standard Buttons) - Reference Style (Very Soft)
        static func medium() -> (light: (Color, CGFloat, CGFloat, CGFloat), dark: (Color, CGFloat, CGFloat, CGFloat)) {
            let light = (Colors.shadowLight, CGFloat(10), CGFloat(-4), CGFloat(-4))
            let dark = (Colors.shadowDark, CGFloat(12), CGFloat(5), CGFloat(5))
            return (light, dark)
        }

        // MARK: Large (Major Panels, Sections) - Reference Style (Very Soft)
        static func large() -> (light: (Color, CGFloat, CGFloat, CGFloat), dark: (Color, CGFloat, CGFloat, CGFloat)) {
            let light = (Colors.shadowLight, CGFloat(12), CGFloat(-5), CGFloat(-5))
            let dark = (Colors.shadowDark, CGFloat(14), CGFloat(6), CGFloat(6))
            return (light, dark)
        }

        // MARK: Extra Large (Floating Elements) - Reference Style (Very Soft)
        static func extraLarge() -> (light: (Color, CGFloat, CGFloat, CGFloat), dark: (Color, CGFloat, CGFloat, CGFloat)) {
            let light = (Colors.shadowLight, CGFloat(16), CGFloat(-7), CGFloat(-7))
            let dark = (Colors.shadowDark, CGFloat(18), CGFloat(8), CGFloat(8))
            return (light, dark)
        }

        // MARK: Enhanced Multi-Layer Shadows for Extreme 3D Depth

        // Small Embossed - Raised appearance with multi-layer shadows
        static func smallEmbossed() -> [(Color, CGFloat, CGFloat, CGFloat)] {
            return [
                (Colors.shadowLight, 8, -3, -3),
                (Colors.shadowDark.opacity(0.15), 10, 4, 4),
                (Colors.highlightLight, 2, -1, -1)
            ]
        }

        // Medium Embossed - Standard raised buttons with strong depth
        static func mediumEmbossed() -> [(Color, CGFloat, CGFloat, CGFloat)] {
            return [
                (Colors.shadowLight, 14, -6, -6),
                (Colors.shadowDark.opacity(0.25), 16, 7, 7),
                (Colors.highlightLight, 3, -2, -2),
                (Colors.shadowDark.opacity(0.12), 8, 3, 3)
            ]
        }

        // Large Embossed - Hero elements with extreme tactile depth
        static func largeEmbossed() -> [(Color, CGFloat, CGFloat, CGFloat)] {
            return [
                (Colors.shadowLight, 20, -8, -8),
                (Colors.shadowDark.opacity(0.3), 24, 10, 10),
                (Colors.highlightLight, 6, -3, -3),
                (Colors.shadowDark.opacity(0.15), 12, 5, 5),
                (Colors.shadowLight.opacity(0.5), 4, -2, -2)
            ]
        }

        // Medium Debossed - Pressed/inset appearance
        static func mediumDebossed() -> [(Color, CGFloat, CGFloat, CGFloat)] {
            return [
                (Colors.shadowDark.opacity(0.35), 10, 4, 4),
                (Colors.shadowLight.opacity(0.6), 8, -3, -3),
                (Colors.shadowDark.opacity(0.2), 4, 2, 2)
            ]
        }

        // Deep Debossed - Strong inset for interactive elements
        static func deepDebossed() -> [(Color, CGFloat, CGFloat, CGFloat)] {
            return [
                (Colors.shadowDark.opacity(0.4), 14, 5, 5),
                (Colors.shadowLight.opacity(0.7), 10, -4, -4),
                (Colors.shadowDark.opacity(0.25), 6, 2, 2),
                (Colors.shadowLight.opacity(0.3), 3, -1, -1)
            ]
        }

        // Legacy compatibility
        static func embossed(radius: CGFloat = 6) -> (light: (Color, CGFloat, CGFloat, CGFloat), dark: (Color, CGFloat, CGFloat, CGFloat)) {
            return medium()
        }

        static func debossed(radius: CGFloat = 6) -> (inner: (Color, CGFloat, CGFloat, CGFloat), outer: (Color, CGFloat, CGFloat, CGFloat)) {
            // Invert shadows for pressed state
            let inner = (Colors.shadowDark, CGFloat(6), CGFloat(3), CGFloat(3))
            let outer = (Colors.shadowLight, CGFloat(6), CGFloat(-3), CGFloat(-3))
            return (inner, outer)
        }

        static func flat(radius: CGFloat = 6) -> (Color, CGFloat, CGFloat, CGFloat) {
            (Colors.shadowDark, radius, 0, radius * 0.5)
        }
    }

    // MARK: - Animation (Smooth, natural)

    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let `default` = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.75)
    }

    // MARK: - Component Sizes

    enum ComponentSize {
        // Buttons
        static let buttonHeightSmall: CGFloat = 40
        static let buttonHeightMedium: CGFloat = 48
        static let buttonHeightLarge: CGFloat = 56

        // Icons
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 20
        static let iconLarge: CGFloat = 24
        static let iconXLarge: CGFloat = 32
        static let iconHero: CGFloat = 48

        // Recording button
        static let recordingButtonSize: CGFloat = 140

        // Rotary knob
        static let rotaryKnobSize: CGFloat = 200
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Neumorphic View Extensions

extension View {
    // MARK: Neumorphic Button (Embossed)

    func neumorphicButton(isPressed: Bool = false) -> some View {
        self
            .background(
                ZStack {
                    // Base surface
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous)
                        .fill(DesignSystem.Colors.surface)

                    if !isPressed {
                        // Embossed effect
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous)
                            .fill(DesignSystem.Colors.surfaceGradient)
                    }
                }
            )
            .shadow(
                color: isPressed ? DesignSystem.Colors.shadowDark.opacity(0.4) : DesignSystem.Colors.highlightLight,
                radius: isPressed ? 4 : 6,
                x: isPressed ? 2 : -3,
                y: isPressed ? 2 : -3
            )
            .shadow(
                color: isPressed ? DesignSystem.Colors.highlightLight.opacity(0.3) : DesignSystem.Colors.shadowDark,
                radius: isPressed ? 3 : 8,
                x: isPressed ? -1 : 4,
                y: isPressed ? -1 : 4
            )
    }

    // MARK: Neumorphic Card

    func neumorphicCard(padding: CGFloat = DesignSystem.Spacing.cardPadding) -> some View {
        self
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                        .fill(DesignSystem.Colors.surface)

                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                        .fill(DesignSystem.Colors.surfaceGradient)
                }
            )
            .shadow(color: DesignSystem.Colors.highlightLight, radius: 6, x: -3, y: -3)
            .shadow(color: DesignSystem.Colors.shadowDark, radius: 8, x: 4, y: 4)
    }

    // MARK: Neumorphic Inset (Debossed)

    func neumorphicInset() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.control, style: .continuous)
                    .fill(DesignSystem.Colors.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.control, style: .continuous)
                    .stroke(DesignSystem.Colors.shadowDark.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: DesignSystem.Colors.shadowDark.opacity(0.3), radius: 4, x: 2, y: 2)
            .shadow(color: DesignSystem.Colors.highlightLight.opacity(0.5), radius: 4, x: -2, y: -2)
    }

    // MARK: Multi-Layer Shadow Helper

    /// Applies multiple shadow layers for enhanced neumorphic depth
    func applyShadows(_ shadows: [(Color, CGFloat, CGFloat, CGFloat)]) -> some View {
        shadows.reduce(AnyView(self)) { view, shadow in
            AnyView(view.shadow(color: shadow.0, radius: shadow.1, x: shadow.2, y: shadow.3))
        }
    }
}

// MARK: - Neumorphic Button Styles

struct NeumorphicButtonStyle: ButtonStyle {
    var accentColor: Color = DesignSystem.Colors.accentBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyMedium)
            .fontWeight(.medium)
            .foregroundStyle(DesignSystem.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.ComponentSize.buttonHeightMedium)
            .neumorphicButton(isPressed: configuration.isPressed)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

struct NeumorphicAccentButtonStyle: ButtonStyle {
    var accentColor: Color = DesignSystem.Colors.accentBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyMedium)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.ComponentSize.buttonHeightMedium)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous)
                        .fill(accentColor)

                    if !configuration.isPressed {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            )
            .shadow(
                color: configuration.isPressed ? accentColor.opacity(0.3) : DesignSystem.Colors.highlightLight,
                radius: configuration.isPressed ? 4 : 6,
                x: configuration.isPressed ? 2 : -3,
                y: configuration.isPressed ? 2 : -3
            )
            .shadow(
                color: configuration.isPressed ? DesignSystem.Colors.shadowDark : accentColor.opacity(0.4),
                radius: configuration.isPressed ? 3 : 12,
                x: configuration.isPressed ? -1 : 4,
                y: configuration.isPressed ? -1 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Neumorphic Design System") {
    ScrollView {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {
            // Typography
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("Neumorphic + Teenage Engineering")
                    .font(DesignSystem.Typography.headlineLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Soft depth with clean minimalism")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Colors
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("Accent Colors")
                    .font(DesignSystem.Typography.titleMedium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                HStack(spacing: DesignSystem.Spacing.small) {
                    Circle().fill(DesignSystem.Colors.accentBlue).frame(width: 40, height: 40)
                    Circle().fill(DesignSystem.Colors.accentCyan).frame(width: 40, height: 40)
                    Circle().fill(DesignSystem.Colors.accentOrange).frame(width: 40, height: 40)
                    Circle().fill(DesignSystem.Colors.accentPink).frame(width: 40, height: 40)
                    Circle().fill(DesignSystem.Colors.accentGreen).frame(width: 40, height: 40)
                    Circle().fill(DesignSystem.Colors.accentPurple).frame(width: 40, height: 40)
                }
            }

            // Buttons
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("Neumorphic Buttons")
                    .font(DesignSystem.Typography.titleMedium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Button("Standard Button") {}
                    .buttonStyle(NeumorphicButtonStyle())

                Button("Accent Button") {}
                    .buttonStyle(NeumorphicAccentButtonStyle(accentColor: DesignSystem.Colors.accentBlue))

                Button("Recording") {}
                    .buttonStyle(NeumorphicAccentButtonStyle(accentColor: DesignSystem.Colors.recording))
            }

            // Card
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("Card Title")
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("This is a neumorphic card with soft shadows creating depth.")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .neumorphicCard()

            // Inset example
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("Debossed / Inset")
                    .font(DesignSystem.Typography.captionLarge)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text("Input field appearance")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding()
            }
            .neumorphicInset()
        }
        .padding(DesignSystem.Spacing.xLarge)
    }
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.light)
}
