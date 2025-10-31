import SwiftUI

/// Neumorphic language selector with embossed button and debossed menu appearance
struct NeumorphicLanguageSelector: View {
    @Binding var selectedLanguageCode: String
    let availableOptions: [LanguageOption]

    @State private var isExpanded = false

    private var selectedLanguageLabel: String {
        availableOptions.first(where: { $0.code == selectedLanguageCode })?.label ?? "Language"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main selector button (embossed when collapsed, debossed when expanded)
            Button(action: {
                withAnimation(DesignSystem.Animation.spring) {
                    isExpanded.toggle()
                    HapticManager.shared.selection()
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "globe")
                        .font(.system(size: DesignSystem.ComponentSize.iconMedium, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accentBlue)

                    Text(selectedLanguageLabel)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 0)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .padding(.vertical, DesignSystem.Spacing.small)
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                        .fill(isExpanded ? DesignSystem.Colors.surfaceDepressed : DesignSystem.Colors.surface)
                )
                .applyShadows(isExpanded ? DesignSystem.NeumorphicShadow.mediumDebossed() : DesignSystem.NeumorphicShadow.mediumEmbossed())
            }
            .buttonStyle(.plain)

            // Expanded language menu (debossed panel)
            if isExpanded {
                VStack(spacing: DesignSystem.Spacing.xxSmall) {
                    ForEach(availableOptions) { option in
                        LanguageOptionRow(
                            option: option,
                            isSelected: option.code == selectedLanguageCode,
                            action: {
                                withAnimation(DesignSystem.Animation.quick) {
                                    selectedLanguageCode = option.code
                                    isExpanded = false
                                    HapticManager.shared.selection()
                                }
                            }
                        )
                    }
                }
                .padding(DesignSystem.Spacing.xSmall)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                        .fill(DesignSystem.Colors.background)
                )
                .applyShadows(DesignSystem.NeumorphicShadow.deepDebossed())
                .padding(.top, DesignSystem.Spacing.xxSmall)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
    }
}

// MARK: - Language Option Row

private struct LanguageOptionRow: View {
    let option: LanguageOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Text(option.label)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accentBlue)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xSmall)
            .padding(.horizontal, DesignSystem.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small, style: .continuous)
                    .fill(isSelected ? DesignSystem.Colors.accentBlue.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Language Selector") {
    VStack(spacing: 32) {
        Text("Language Selector - Collapsed & Expanded")
            .font(DesignSystem.Typography.headlineSmall)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

        NeumorphicLanguageSelector(
            selectedLanguageCode: .constant("en-US"),
            availableOptions: LanguageOption.baseOptions
        )

        Spacer()
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.light)
}
