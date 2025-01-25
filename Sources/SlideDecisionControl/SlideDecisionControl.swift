//
//  SlideDecisionControl.swift
//  SlideDecisionControl
//
//  Created by Andriy Kachalo on 19/01/2025.
//	Copyright © 2025 Eyen S.a.r.l. All Rights Reserved.
//

import SwiftUI

let kAnimationMultiplier: Double = 1.0

/// A SwiftUI control that allows explicit decision-making through sliding gestures.
/// Designed to prevent accidental actions and ensure deliberate user interactions.
public struct SlideDecisionControl: View {
	
	/// Represents the possible actions within the control.
	public enum Action: Hashable, Sendable {
		/// Accept action, indicating a positive decision.
		case accept
		/// Middle action, representing a neutral or intermediate state.
		case middle
		/// Reject action, indicating a negative decision.
		case reject
	}
	
	/// Defines the types of images that can be used within the control.
	public enum ImageName {
		/// Uses a system-provided SF Symbol.
		/// - Parameter name: The SF Symbol name.
		case system(name: String)
		
		/// Uses a regular custom image.
		/// - Parameter name: The name of the custom image asset.
		case regular(name: String)
	}

	/// Initializes a `SlideDecisionControl` instance with customizable icons, labels, and action handlers.
	///
	/// - Parameters:
	///   - imageAccept: The image displayed for the 'accept' action. Defaults to the SF Symbol `"hand.thumbsup"`.
	///   - textAccept: An optional localized string for the 'accept' button label.
	///   - imageMiddle: The image displayed for the 'middle' action. Defaults to the SF Symbol `"bookmark"`.
	///   - imageReject: The image displayed for the 'reject' action. Defaults to the SF Symbol `"hand.thumbsdown"`.
	///   - textReject: An optional localized string for the 'reject' button label.
	///   - action: A closure that is triggered when an action is selected, returning the chosen `Action`.
	public init(
			imageAccept: ImageName = .system(name: "hand.thumbsup"),
			textAccept inTextAccept: LocalizedStringKey? = nil,
			imageMiddle: ImageName = .system(name: "bookmark"),
			imageReject: ImageName = .system(name: "hand.thumbsdown"),
			textReject inTextReject: LocalizedStringKey? = nil,
			action inAction: @escaping @Sendable (Action) -> Void
		) {
		imageNameAccept = imageAccept
		imageNameMiddle = imageMiddle
		imageNameReject = imageReject
		
		textAccept = inTextAccept
		textReject = inTextReject
		
		action = inAction
	}
	
	let imageNameAccept: ImageName
	let imageNameMiddle: ImageName
	let imageNameReject: ImageName
	
	let textAccept: LocalizedStringKey?
	let textReject: LocalizedStringKey?
	
	private enum Side: Hashable, Sendable {
		case leading
		case trailing
	}
	
	private enum InteractionState: Hashable {
		case idle
		case demo(side: Side)
		case startingDrag(side: Side)
		case dragging(side: Side, offset: CGFloat)
		case allIn(side: Side)
		case selection(side: Side)
	}
	@State private var interactionState: InteractionState = .idle
	
	@State private var moveGradient: Bool = false
	@State private var pulsation: CGFloat = 0
	@State private var symbolEffect: Bool = false
	
	@Namespace var animation
	
	let action: @Sendable (Action) -> Void
		
	private var imageLeading: Image {
		image(for: imageNameAccept)
	}
	
	private var imageMiddle: Image {
		image(for: imageNameMiddle)
	}
	
	private var imageTrailing: Image {
		image(for: imageNameReject)
	}
	
	private func image(for name: ImageName) -> Image {
		switch name {
		case .system(let name):
			Image(systemName: name)
		case .regular(let name):
			Image(name)
		}
	}
	
	let kSelectionScaleFactor: CGFloat = 1.5
	
	public var body: some View {
		HStack(alignment: .firstTextBaseline, spacing: kGap) {
			
			if case .selection(let side) = interactionState {
				Group {
					switch side {
					case .leading:
						imageLeading
					case .trailing:
						imageTrailing
					}
				}
					.matchedGeometryEffect(id: side, in: animation)
					.font(font)
					.foregroundStyle(.white)
					.symbolEffect(side == .leading ? .bounce.up.byLayer : .bounce.down.byLayer, value: symbolEffect)
					.frame(width: kButtonSize * kSelectionScaleFactor, height: kButtonSize * kSelectionScaleFactor)
					.scaleEffect(CGSize(width: kSelectionScaleFactor, height: kSelectionScaleFactor))
			} else {
				imageLeading
					.matchedGeometryEffect(id: Side.leading, in: animation)
					.frame(width: kButtonSize, height: kButtonSize)
					.opacity(buttonOpacity(.leading))
					.scaleEffect(buttonScale(.leading))
					.offset(x: offsetLeadingButton)
					.onTapGesture {
						handleTap(on: .leading)
					}
					.onLongPressGesture(minimumDuration: 0.01) {
						startDrag(on: .leading)
					} onPressingChanged: { _ in
						if case .startingDrag = interactionState {
							switchToIdle()
						}
					}
					.simultaneousGesture(
						DragGesture()
							.onChanged { gesture in
								handleGestureChange(for: .leading, with: gesture.translation.width)
							}
							.onEnded { _ in
								handleEndGesture()
							}
					)
				
				Button {
					action(.middle)
				}
				label: {
					imageMiddle
						.tint(.primary)
				}
				.frame(width: kButtonSize, height: kButtonSize)
				.opacity(buttonOpacity)
				.scaleEffect(buttonScale)
				
				imageTrailing
					.matchedGeometryEffect(id: Side.trailing, in: animation)
					.frame(width: kButtonSize, height: kButtonSize)
					.opacity(buttonOpacity(.trailing))
					.scaleEffect(buttonScale(.trailing))
					.offset(x: offsetTrailingButton)
					.onTapGesture {
						handleTap(on: .trailing)
					}
					.onLongPressGesture(minimumDuration: 0.01) {
						startDrag(on: .trailing)
					} onPressingChanged: { _ in
						if case .startingDrag = interactionState {
							switchToIdle()
						}
					}
					.simultaneousGesture(
						DragGesture()
							.onChanged { gesture in
								handleGestureChange(for: .trailing, with: -gesture.translation.width)
							}
							.onEnded { _ in
								handleEndGesture()
							}
					)
			}
		}
		.font(font)
		.tint(.white)
		.padding(kBorder + pulsation)
		.padding(.leading, extraExpansionLeading)
		.padding(.trailing, extraExpansionTrailing)
		.background(alignment: .trailing) {
			foregroundCapsule(Color("slide.destructive.light", bundle: .module))
				.opacity(shouldChangeBackgroundToRed ? 1 : 0)
		}
		.background(alignment: .leading) {
			foregroundCapsule(Color("slide.accept.light", bundle: .module))
				.opacity(shouldChangeBackgroundToGreen ? 1 : 0)
		}
		.background {
			Group {
				if shouldChangeBackgroundToRed {
					ZStack {
						backgroundCapsule(Color("slide.destructive.dark", bundle: .module))
						text(for: .trailing)
							.padding(.trailing, kButtonSize)
					}
				} else if shouldChangeBackgroundToGreen {
					ZStack {
						backgroundCapsule(Color("slide.accept.dark", bundle: .module))
						text(for: .leading)
							.padding(.leading, kButtonSize)
					}
				} else if case .selection(let side) = interactionState {
					switch side {
					case .leading:
						backgroundCapsule(Color("slide.accept.light", bundle: .module))
					case .trailing:
						backgroundCapsule(Color("slide.destructive.light", bundle: .module))
					}
				} else {
					backgroundCapsule(.ultraThickMaterial)
				}
			}
		}
		.environment(\.colorScheme, .dark)
		.padding(.leading, extraExpansionTrailing)
		.padding(.trailing, extraExpansionLeading)
		.animation(.linear(duration: 1.5).delay(0.25).repeatForever(autoreverses: false), value: moveGradient)
		.sensoryFeedback(trigger: interactionState, hapticFeedback)
//		.animation(pulsationAnimation, value: pulsation)
//		.onChange(of: interactionState) { oldState, newState in
//			let newValue = shouldPulsate(in: newState)
//			let oldValue = shouldPulsate(in: oldState)
//			guard newValue != oldValue else { return }
//			if newValue {
//				pulsation = kMaxPulsation
//			} else {
//				pulsation = 0
//			}
//		}
	}
	
	var font: Font {
		.system(size: 28, weight: .medium)
	}
	
	@ViewBuilder
	func backgroundCapsule(_ content: some ShapeStyle) -> some View {
		Capsule(style: .circular)
			.fill(content)
			.matchedGeometryEffect(id: "background", in: animation)
			.shadow(color: .black.opacity(0.65), radius: 1)
			.shadow(color: shadowColor, radius: shadowRadius, y: shadowOffset)
	}
	
	@ViewBuilder
	func foregroundCapsule(_ content: some ShapeStyle) -> some View {
		Capsule(style: .circular)
			.fill(content)
			.frame(width: progressWidth, height: kButtonSize)
			.padding(kBorder + pulsation)
	}
	
	private func shouldPulsate(in state: InteractionState) -> Bool {
		guard case .allIn = state else { return false }
		return true
	}
	
	private func placeholderText(for side: Side) -> LocalizedStringKey {
		switch side {
		case .leading:
			textAccept ?? "Slide to accept"
		case .trailing:
			textReject ?? "Slide to reject"
		}
	}
	
	@ViewBuilder
	private func text(for side: Side) -> some View {
		Text(placeholderText(for: side))
			.font(.body.weight(.heavy))
			.fontDesign(.rounded)
			.textCase(.uppercase)
			.padding(.horizontal)
			.foregroundStyle(textGradient(side))
			.opacity(textOpacity)
			.onAppear {
				moveGradient = true
			}
			.onDisappear {
				moveGradient = false
			}
	}
	
	private func hapticFeedback(_ oldValue: InteractionState, _ newValue: InteractionState) -> SensoryFeedback? {
		if oldValue == .idle {
			.impact(flexibility: .rigid)
		} else if newValue == .idle {
			.impact(flexibility: .soft)
		} else if case .dragging(_, let oldOffset) = oldValue,
			case .dragging(_, let newOffset) = newValue,
					oldOffset < maxWidth,
					newOffset >= maxWidth {
			.impact(flexibility: .solid)
		} else {
			nil
		}
	}
	
	let kExtraExpansion: CGFloat = 68
	let kButtonSize: CGFloat = 56
	let kGap: CGFloat = 8
	let kBorder: CGFloat = 4
	let kMaxDemoOffset: CGFloat = 24
	let kDemoAnimationDuration: TimeInterval = 0.35 * kAnimationMultiplier
	let kDemoAnimationStallDuration: TimeInterval = 0.25 * kAnimationMultiplier
	let kSelectionAnimationDuration: TimeInterval = 0.35 * kAnimationMultiplier
	let kSelectionAnimationStallDuration: TimeInterval = 0.75 * kAnimationMultiplier
	let kMinButtonScale: CGFloat = 0.85
	let kMaxButtonScale: CGFloat = 1.15
	let kMaxPulsation: CGFloat = 3
	
	private var interactionSide: Side? {
		switch interactionState {
		case .idle:
			return nil
		case .demo(let side), .startingDrag(let side), .dragging(let side, _), .allIn(let side), .selection(let side):
			return side
		}
	}
	
	private func buttonOpacity(_ inSide: Side) -> CGFloat {
		guard let side = interactionSide else { return 1 }
		return (side == inSide) ? 1 : 0
	}
	
	private var buttonOpacity: CGFloat {
		(interactionState == .idle) ?  1 : 0
	}
	
	private func buttonScale(_ inSide: Side) -> CGSize {
		guard let side = interactionSide else { return CGSize(width: 1, height: 1) }
		return (side == inSide) ?
			CGSize(width: kMaxButtonScale, height: kMaxButtonScale) :
			CGSize(width: kMinButtonScale, height: kMinButtonScale)
	}
	
	private var buttonScale: CGSize {
		(interactionState != .idle) ?
			CGSize(width: kMinButtonScale, height: kMinButtonScale) :
			CGSize(width: 1, height: 1)
	}
		
	private var offsetLeadingButton: CGFloat {
		if case .dragging(let side, let offset) = interactionState, side == .leading {
			return min(max(0, offset), maxOffset)
		} else if case .allIn(let side) = interactionState, side == .leading {
			return maxOffset + pulsation
		} else if case .demo(let side) = interactionState, side == .leading {
			return kMaxDemoOffset
		}
		return 0
	}
	
	private var offsetTrailingButton: CGFloat {
		if case .dragging(let side, let offset) = interactionState, side == .trailing {
			return -min(max(0, offset), maxOffset)
		} else if case .allIn(let side) = interactionState, side == .trailing {
			return -maxOffset - pulsation
		} else if case .demo(let side) = interactionState, side == .trailing {
			return -kMaxDemoOffset
		}
		return 0
	}
	
	private var maxWidth: CGFloat {
		kButtonSize * 3 + kGap * 2 + extraExpansionLeading + extraExpansionTrailing
	}
	
	private var maxOffset: CGFloat {
		maxWidth - kButtonSize
	}
	
	private var progressWidth: CGFloat {
		min(max(kButtonSize, kButtonSize + offsetLeadingButton + abs(offsetTrailingButton)), maxWidth)
	}
	
	private var extraExpansionLeading: CGFloat {
		guard let side = interactionSide else { return 0 }
		if case .selection = interactionState { return 0
		}
		return (side == .leading) ? 0 : kExtraExpansion
	}
	
	private var extraExpansionTrailing: CGFloat {
		guard let side = interactionSide else { return 0 }
		if case .selection = interactionState { return 0
		}
		return (side == .trailing) ? 0 : kExtraExpansion
	}
	
	private var shouldChangeBackgroundToRed: Bool {
		guard let side = interactionSide else { return false }
		if case .selection = interactionState { return false
		}
		return (side == .trailing)
	}
	
	private var shouldChangeBackgroundToGreen: Bool {
		guard let side = interactionSide else { return false }
		if case .selection = interactionState { return false
		}
		return (side == .leading)
	}
	
	private var textOpacity: CGFloat {
		if case .dragging(_, let offset) = interactionState {
			return 1 - pow(min(1, offset / (maxOffset * 0.75)), 2)
		}
		return 1
	}
		
	private var interactionAnimation: Animation {
		.smooth(duration: 0.35 * kAnimationMultiplier/*, extraBounce: 0.25*/)
	}
	
	private var pulsationAnimation: Animation? {
		shouldPulsate(in: interactionState) ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .none
	}
	
	private var shadowColor: Color {
		let baseColor: Color = switch interactionSide {
			case .trailing:
				Color("slide.destructive.dark", bundle: .module)
			case .leading:
				Color("slide.accept.dark", bundle: .module)
			case nil:
				.black
			}
		
		switch interactionState {
		case .startingDrag, .dragging, .allIn:
			return baseColor.opacity(0.4)
		case .demo:
			return baseColor.opacity(0.25)
		default:
			return .black.opacity(0.12)
		}
	}
	
	private var shadowRadius: CGFloat {
		switch interactionState {
		case .startingDrag, .dragging, .allIn:
			return 15
		default:
			return 5
		}
	}
	
	private var shadowOffset: CGFloat {
		switch interactionState {
		case .startingDrag, .dragging, .allIn:
			return 8
		default:
			return 5
		}
	}
	
	private func textGradient(_ side: Side) -> LinearGradient {
		let colors: [Color] = [.white.opacity(0.25), .white, .white.opacity(0.25)]
		switch side {
		case .leading:
			return LinearGradient(
				colors: colors,
				startPoint: .init(x: moveGradient ?  1 : -1, y: 0),
				endPoint: .init(x: moveGradient ?  2 : 0, y: 0)
			)
		case .trailing:
			return LinearGradient(
				colors: colors,
				startPoint: .init(x: moveGradient ?  -1 : 1, y: 0),
				endPoint: .init(x: moveGradient ?  0 : 2, y: 0)
			)
		}
	}
	
	private func handleTap(on side: Side) {
		withAnimation(.easeOut(duration: kDemoAnimationDuration)) {
			interactionState = .demo(side: side)
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + kDemoAnimationDuration + kDemoAnimationStallDuration) {
			withAnimation(.spring(response: 0.4 * kAnimationMultiplier, dampingFraction: 0.5, blendDuration: 0.5)) {
				interactionState = .idle
			}
		}
	}
	
	private func handleGestureChange(for side: Side, with newOffset: CGFloat) {
		if newOffset >= maxOffset {
			interactionState = .allIn(side: side)
		} else {
			interactionState = .dragging(side: side, offset: newOffset)
		}
	}
	
	private func handleEndGesture() {
		if case .allIn(let side) = interactionState {
			withAnimation(interactionAnimation) {
				interactionState = .selection(side: side)
			}
			
			DispatchQueue.main
				.asyncAfter(deadline: .now() + 0.35 * kAnimationMultiplier) {
				symbolEffect.toggle()
			}
			
			DispatchQueue.main
				.asyncAfter(deadline: .now() + kSelectionAnimationDuration + kSelectionAnimationStallDuration) {
				
				switch side {
				case .leading:
					action(.accept)
				case .trailing:
					action(.reject)
				}
				
				withAnimation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.5)) {
					interactionState = .idle
				}
			}
		} else {
			switchToIdle()
		}
	}
	
	private func startDrag(on side: Side) {
		withAnimation(interactionAnimation) {
			interactionState = .startingDrag(side: side)
		}
	}
	
	private func switchToIdle() {
		withAnimation(interactionAnimation) {
			interactionState = .idle
		}
	}
}

#Preview("Default") {
	SlideDecisionControl { _ in
	}
}

#Preview("Customized") {
	SlideDecisionControl(
		imageAccept: .system(name: "heart"),
		textAccept: "Slide to Love",
		imageMiddle: .system(name: "bubble"),
		imageReject: .system(name: "xmark.circle"),
		textReject: "Slide to Hate"
	) { _ in
	}
}
