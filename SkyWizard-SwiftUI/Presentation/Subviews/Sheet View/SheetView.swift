//
//  SheetView.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 03/11/2024.
//

import SwiftUI

/// The drag-up panel that overlays the weather scene on the phone layout.
///
/// Two detents: collapsed (a peek at the bottom) and expanded (near the top).
/// A drag anywhere on the panel moves it, except while the content is scrolled
/// away from the top — then the gesture belongs to the scroll view, exactly
/// like a system sheet. The scroll view is disabled at the top so a single
/// vertical touch drives the sheet instead of fighting a bounce.
struct SheetView<Content: View>: View {

    var fill: Color = .white
    var shadowRadius: CGFloat = 10
    var opacity: Double = 0.1
    var cornerRadius: CGFloat = 30
    var isHandleVisible: Bool = false
    var isBackgroundVisible: Bool = true

    @Binding var isPresented: Bool
    var content: () -> Content

    @Environment(\.isCompactScreen) private var isCompactScreen

    /// Distance from the top of the screen to the top edge of the sheet when fully expanded.
    private let topClearance: CGFloat = 160
    /// Height of the peeked area that stays visible at the bottom when the sheet is collapsed.
    private var peekHeight: CGFloat {
        // Compact screens (SE / mini) are shorter, so a smaller peek keeps
        // more of the weather scene visible without breaking the layout.
        isCompactScreen ? 250 : 300
    }
    /// Clear space kept under the last content row so it never sits under the
    /// home indicator.
    private let bottomSafeClearance: CGFloat = 64
    /// Scroll offset below which the content counts as "at the top" and the
    /// sheet may own a downward drag.
    private let scrollOwnershipThreshold: CGFloat = 1
    /// Vertical drag distance before the gesture counts, and the bias
    /// favouring vertical drags over sideways ones while latching on.
    private let dragDeadZone: CGFloat = 6
    private let verticalDragBias: CGFloat = 1.2
    /// Weight applied to the projected finger velocity while settling on a detent.
    private let settlingVelocityGain: CGFloat = 0.35
    /// Spring used when animating between the collapsed and expanded detents.
    private var snapAnimation: Animation { .interactiveSpring(duration: 0.4, extraBounce: 0) }

    @State private var sheetOffset: CGFloat = 0
    @State private var isDraggingSheet: Bool = false
    @State private var dragStartOffset: CGFloat = 0
    @State private var dragStartTranslation: CGFloat = 0
    @State private var scrollState = SheetScrollState()

    var body: some View {
        GeometryReader { proxy in
            let detents = SheetDetents(
                containerHeight: proxy.size.height,
                topClearance: topClearance,
                peekHeight: peekHeight
            )

            ZStack(alignment: .top) {
                if isBackgroundVisible {
                    Rectangle()
                        .foregroundStyle(fill.opacity(opacity))
                        .background(.ultraThinMaterial)
                        .shadow(radius: shadowRadius)
                        .clipShape(CustomCorner(corners: [.topLeft, .topRight], radius: cornerRadius))
                }

                panelContent(detents: detents)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .clipShape(CustomCorner(corners: [.topLeft, .topRight], radius: cornerRadius))
            }
            .frame(height: detents.sheetHeight)
            .offset(y: sheetOffset)
            .onAppear {
                sheetOffset = detents.restingOffset(presented: isPresented)
            }
            .onChange(of: isPresented) { _, newValue in
                settleDetent(to: detents, presented: newValue)
            }
            .onChange(of: proxy.size.height) {
                // The container resizes while folding, rotating, or under
                // multitasking; glide to the moved detent instead of jumping.
                let moved = SheetDetents(
                    containerHeight: proxy.size.height,
                    topClearance: topClearance,
                    peekHeight: peekHeight
                )
                settleDetent(to: moved, presented: isPresented)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

    private func panelContent(detents: SheetDetents) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                if isBackgroundVisible && isHandleVisible {
                    Capsule()
                        .fill(.black)
                        .frame(width: 68, height: 4, alignment: .center)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                }

                content()

                // Always reserve room for the home indicator, whether the
                // panel paints its own background or sits over the scene.
                Color.clear
                    .frame(height: bottomSafeClearance)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        // Disabled while collapsed and while the sheet is being dragged —
        // the drag ends any in-flight scroll so a single vertical touch near
        // the top moves the sheet, never both the sheet and a bounce.
        .scrollDisabled(!isPresented || isDraggingSheet)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newValue in
            scrollState.contentOffset = newValue
        }
        .onScrollPhaseChange { _, newPhase in
            scrollState.isScrolling = newPhase.isScrolling
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: dragDeadZone)
                .onChanged { value in
                    onDragChanged(
                        translation: value.translation.height,
                        horizontalTranslation: value.translation.width,
                        detents: detents
                    )
                }
                .onEnded { value in
                    onDragEnded(
                        translation: value.translation.height,
                        predictedEndTranslation: value.predictedEndTranslation.height,
                        detents: detents
                    )
                }
        )
    }

    private func onDragChanged(
        translation: CGFloat,
        horizontalTranslation: CGFloat,
        detents: SheetDetents
    ) {
        guard canStartDraggingSheet(translation: translation, horizontalTranslation: horizontalTranslation) else {
            return
        }

        if !isDraggingSheet {
            isDraggingSheet = true
            dragStartOffset = sheetOffset
            dragStartTranslation = translation
        }

        let proposed = dragStartOffset + (translation - dragStartTranslation)
        let clamped = min(detents.collapsedOffset, max(detents.expandedOffset, proposed))
        guard clamped != sheetOffset else { return }
        sheetOffset = clamped
    }

    private func onDragEnded(
        translation: CGFloat,
        predictedEndTranslation: CGFloat,
        detents: SheetDetents
    ) {
        guard isDraggingSheet else { return }

        let projected = sheetOffset + ((predictedEndTranslation - translation) * settlingVelocityGain)
        let midpoint = (detents.expandedOffset + detents.collapsedOffset) / 2
        let shouldExpand = projected < midpoint
        let target = shouldExpand ? detents.expandedOffset : detents.collapsedOffset

        isDraggingSheet = false
        withAnimation(snapAnimation) {
            sheetOffset = target
            isPresented = shouldExpand
        }
    }

    private func canStartDraggingSheet(translation: CGFloat, horizontalTranslation: CGFloat) -> Bool {
        if isDraggingSheet { return true }

        let isStrictlyVertical = abs(translation) >= abs(horizontalTranslation) * verticalDragBias
        guard isStrictlyVertical, abs(translation) > dragDeadZone else { return false }

        if isPresented {
            // Only take the gesture when the content has settled at (or
            // above) the top: a rubber-band overshoot leaves negative
            // offsets behind, and grabbing mid-scroll fights the deceleration.
            return translation > 0
                && !scrollState.isScrolling
                && scrollState.contentOffset <= scrollOwnershipThreshold
        }
        return true
    }

    private func settleDetent(to detents: SheetDetents, presented: Bool) {
        guard !isDraggingSheet else { return }
        let target = detents.restingOffset(presented: presented)
        guard sheetOffset != target else { return }
        withAnimation(snapAnimation) {
            sheetOffset = target
        }
    }
}

/// The two resting positions of the panel, measured from the top of its
/// container, plus the travel between them.
private struct SheetDetents {
    let collapsedOffset: CGFloat
    let expandedOffset: CGFloat
    let sheetHeight: CGFloat

    init(containerHeight: CGFloat, topClearance: CGFloat, peekHeight: CGFloat) {
        collapsedOffset = containerHeight - peekHeight
        expandedOffset = min(collapsedOffset, max(topClearance, 0))
        sheetHeight = (collapsedOffset - expandedOffset) + peekHeight
    }

    func restingOffset(presented: Bool) -> CGFloat {
        presented ? expandedOffset : collapsedOffset
    }
}

private final class SheetScrollState {
    var contentOffset: CGFloat = 0
    var isScrolling: Bool = false
}

private struct CustomCorner: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return .init(path.cgPath)
    }
}

#if DEBUG
#Preview {
    StatePreviewWrapper(value: true) { $value in
        ZStack {
            GeometryReader { proxy in
                let frame = proxy.frame(in: .global)

                Image(.mountain)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: frame.width, height: frame.height)
            }
            .ignoresSafeArea()
            SheetView(isPresented: $value) {
                VStack(spacing: 14) {
                    ForEach(0..<12) { index in
                        Text("Scrollable row \(index)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.white.opacity(0.15), in: .rect(cornerRadius: 16))
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .onTapGesture {
            value = false
        }
    }
}
#endif
