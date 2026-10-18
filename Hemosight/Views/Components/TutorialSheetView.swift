import SwiftUI

// MARK: - Elderly-Accessible Visual Tutorial Onboarding Sheet

public struct TutorialSheetView: View {
    @Binding public var isPresented: Bool
    @AppStorage("hide_tutorial_on_launch") private var hideTutorialOnLaunch: Bool = false
    @State private var currentSlide: Int = 0
    @Environment(\.appLanguage) private var appLanguage
    
    private let totalSlides = 4
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Carousel Page View
                TabView(selection: $currentSlide) {
                    slide1VisualPhoto
                        .tag(0)
                    slide2FingerPulse
                        .tag(1)
                    slide3ToePulse
                        .tag(2)
                    slide4ReportSummary
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                Divider()
                    .padding(.top, 4)
                
                // Footer Controls: Checkbox & Primary Button
                footerControls
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(HemosightStrings.tutorialTitle(for: appLanguage))
                        .appFont(size: 16, weight: .bold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(HemosightStrings.tutorialCloseButton(for: appLanguage))
                }
            }
        }
    }
    
    // MARK: - Slide 1: Bilateral Foot Photo
    
    private var slide1VisualPhoto: some View {
        slideContent(
            stepBadge: HemosightStrings.tutorialStep1Subtitle(for: appLanguage),
            title: HemosightStrings.tutorialStep1Title(for: appLanguage),
            badgeColor: .blue,
            ruleText: HemosightStrings.tutorialStep1Rule(for: appLanguage)
        ) {
            // Visual Graphic Card: Bare Feet Placement
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.blue.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundStyle(Color.blue.opacity(0.35))
                    )
                
                VStack(spacing: 14) {
                    HStack(spacing: 28) {
                        // Left Foot
                        VStack(spacing: 6) {
                            Image(systemName: "shoe.2.fill")
                                .font(.system(size: 54))
                                .foregroundStyle(.blue)
                            Text("ซ้าย / L")
                                .appFont(size: 11, weight: .bold)
                                .foregroundStyle(.blue.opacity(0.8))
                        }
                        
                        // Right Foot
                        VStack(spacing: 6) {
                            Image(systemName: "shoe.2.fill")
                                .font(.system(size: 54))
                                .foregroundStyle(.blue)
                            Text("ขวา / R")
                                .appFont(size: 11, weight: .bold)
                                .foregroundStyle(.blue.opacity(0.8))
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(.orange)
                        Text("แสงสว่างพอเหมาะ • ไม่สวมถุงเท้า")
                            .appFont(size: 12, weight: .semibold)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(Capsule())
                }
                .padding()
            }
            .frame(height: 180)
        }
    }
    
    // MARK: - Slide 2: Fingertip Pulse (PPG)
    
    private var slide2FingerPulse: some View {
        slideContent(
            stepBadge: HemosightStrings.tutorialStep2Subtitle(for: appLanguage),
            title: HemosightStrings.tutorialStep2Title(for: appLanguage),
            badgeColor: .red,
            ruleText: HemosightStrings.tutorialStep2Rule(for: appLanguage)
        ) {
            // Visual Graphic Card: Fingertip on Camera Lens & Flash
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.red.opacity(0.25), lineWidth: 1.5)
                    )
                
                VStack(spacing: 14) {
                    HStack(spacing: 20) {
                        // Lens & Flash Illustration
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.85))
                                .frame(width: 60, height: 60)
                            Circle()
                                .stroke(Color.gray.opacity(0.5), lineWidth: 3)
                                .frame(width: 48, height: 48)
                            Image(systemName: "camera.aperture")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                            
                            // Glowing LED Flash indicator
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 14, height: 14)
                                .offset(x: 22, y: -22)
                                .shadow(color: .yellow, radius: 4)
                        }
                        
                        Image(systemName: "arrow.right")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        // Finger placement icon
                        VStack(spacing: 4) {
                            Image(systemName: "hand.point.up.fill")
                                .font(.system(size: 46))
                                .foregroundStyle(.red)
                            Text("นิ้วชี้มือ")
                                .appFont(size: 11, weight: .bold)
                                .foregroundStyle(.red.opacity(0.8))
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(.red)
                        Text("แตะเบาๆ ไม่กดแน่น • นิ่งไว้ 30 วินาที")
                            .appFont(size: 12, weight: .semibold)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(Capsule())
                }
                .padding()
            }
            .frame(height: 180)
        }
    }
    
    // MARK: - Slide 3: Big Toe Pulse (PPG)
    
    private var slide3ToePulse: some View {
        slideContent(
            stepBadge: HemosightStrings.tutorialStep3Subtitle(for: appLanguage),
            title: HemosightStrings.tutorialStep3Title(for: appLanguage),
            badgeColor: .purple,
            ruleText: HemosightStrings.tutorialStep3Rule(for: appLanguage)
        ) {
            // Visual Graphic Card: Toe on Camera while seated
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.purple.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.purple.opacity(0.25), lineWidth: 1.5)
                    )
                
                VStack(spacing: 14) {
                    HStack(spacing: 24) {
                        // Seated posture
                        VStack(spacing: 4) {
                            Image(systemName: "chair.lounge.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.purple)
                            Text("นั่งสบายๆ")
                                .appFont(size: 11, weight: .bold)
                                .foregroundStyle(.purple.opacity(0.8))
                        }
                        
                        Image(systemName: "plus")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        
                        // Big Toe Contact
                        VStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 40))
                                .foregroundStyle(.purple)
                            Text("นิ้วโป้งเท้า")
                                .appFont(size: 11, weight: .bold)
                                .foregroundStyle(.purple.opacity(0.8))
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .foregroundStyle(.purple)
                        Text("วางนิ้วโป้งเท้าปิดเลนส์ • วัด 30 วินาที")
                            .appFont(size: 12, weight: .semibold)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(Capsule())
                }
                .padding()
            }
            .frame(height: 180)
        }
    }
    
    // MARK: - Slide 4: Clinical Report & Doctor Referral
    
    private var slide4ReportSummary: some View {
        slideContent(
            stepBadge: HemosightStrings.tutorialStep4Subtitle(for: appLanguage),
            title: HemosightStrings.tutorialStep4Title(for: appLanguage),
            badgeColor: .teal,
            ruleText: HemosightStrings.tutorialStep4Rule(for: appLanguage)
        ) {
            // Visual Graphic Card: Report Preview & Doctor Referral
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.teal.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.teal.opacity(0.25), lineWidth: 1.5)
                    )
                
                VStack(spacing: 12) {
                    HStack(spacing: 18) {
                        // PDF Document Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.teal.opacity(0.18))
                                .frame(width: 50, height: 62)
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.teal)
                        }
                        
                        // 3 Risk Tiers
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle().fill(.green).frame(width: 10, height: 10)
                                Text("ความเสี่ยงต่ำ (Low)")
                                    .appFont(size: 11, weight: .semibold)
                            }
                            HStack(spacing: 6) {
                                Circle().fill(.orange).frame(width: 10, height: 10)
                                Text("ความเสี่ยงปานกลาง (Borderline)")
                                    .appFont(size: 11, weight: .semibold)
                            }
                            HStack(spacing: 6) {
                                Circle().fill(.red).frame(width: 10, height: 10)
                                Text("ความเสี่ยงสูง (High Risk)")
                                    .appFont(size: 11, weight: .semibold)
                            }
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "cross.case.fill")
                            .foregroundStyle(.teal)
                        Text("สร้างรายงาน PDF 1 หน้าสำหรับปรึกษาแพทย์")
                            .appFont(size: 12, weight: .semibold)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(Capsule())
                }
                .padding()
            }
            .frame(height: 180)
        }
    }
    
    // MARK: - Slide Content Template
    
    private func slideContent<Graphic: View>(
        stepBadge: String,
        title: String,
        badgeColor: Color,
        ruleText: String,
        @ViewBuilder graphic: () -> Graphic
    ) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                // Step Badge
                Text(stepBadge.uppercased())
                    .appFont(size: 12, weight: .bold)
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.top, 8)
                
                // Title
                Text(title)
                    .appFont(size: appLanguage == .thai ? 20 : 22, weight: .bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .toneMarkSafePadding(.horizontal, 8)
                
                // Graphic Card
                graphic()
                    .padding(.horizontal, 20)
                
                // Key Rules Box
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(badgeColor)
                        .padding(.top, 2)
                    
                    Text(ruleText)
                        .appFont(size: appLanguage == .thai ? 14.5 : 15, weight: .regular)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 14))
                .padding(.horizontal, 20)
                
                Spacer(minLength: 24)
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Footer Controls
    
    private var footerControls: some View {
        VStack(spacing: 14) {
            // Checkbox: Don't show this tutorial again
            Button {
                hideTutorialOnLaunch.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: hideTutorialOnLaunch ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(hideTutorialOnLaunch ? Color.blue : Color.secondary)
                    
                    Text(HemosightStrings.dontShowAgainCheckbox(for: appLanguage))
                        .appFont(size: appLanguage == .thai ? 13.5 : 14, weight: .medium)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(HemosightStrings.dontShowAgainCheckbox(for: appLanguage)), \(hideTutorialOnLaunch ? "checked" : "unchecked")")
            
            // Primary Action Button (> 56pt touch target)
            Button {
                if currentSlide < totalSlides - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentSlide += 1
                    }
                } else {
                    isPresented = false
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentSlide < totalSlides - 1
                         ? HemosightStrings.nextButton(for: appLanguage)
                         : HemosightStrings.startScreeningButton(for: appLanguage))
                        .appFont(size: appLanguage == .thai ? 17 : 18, weight: .bold)
                    
                    Image(systemName: currentSlide < totalSlides - 1 ? "arrow.right" : "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 14))
            }
            .accessibilityLabel(currentSlide < totalSlides - 1
                                ? HemosightStrings.nextButton(for: appLanguage)
                                : HemosightStrings.startScreeningButton(for: appLanguage))
        }
    }
}

// MARK: - Previews

#Preview("Tutorial Sheet - Thai Language") {
    TutorialSheetView(isPresented: .constant(true))
        .environment(\.appLanguage, .thai)
}

#Preview("Tutorial Sheet - English Language") {
    TutorialSheetView(isPresented: .constant(true))
        .environment(\.appLanguage, .english)
}
