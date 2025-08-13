import SwiftUI

struct DraggableCoachBubble: View {
    @Binding var isOpen: Bool
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    private let size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                .overlay(
                    Image(systemName: "figure.run.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .padding(12)
                        .shadow(color: .white.opacity(0.4), radius: 3)
                )
                .scaleEffect(isDragging ? 1.08 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
        }
        .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    // Live-follow during drag; on end, snap to nearest edge
                    let total = CGSize(width: offset.width + value.translation.width,
                                       height: offset.height + value.translation.height)
                    let screen = UIScreen.main.bounds
                    let leftDistance = -screen.width/2 + size/2 + 16
                    let rightDistance = screen.width/2 - size/2 - 16
                    // Snap horizontally to closer edge, keep y within safe bounds
                    let targetX: CGFloat = (total.width < 0) ? leftDistance : rightDistance
                    let topBound = -screen.height/2 + size/2 + 80
                    let bottomBound = screen.height/2 - size/2 - 80
                    let clampedY = min(max(total.height, topBound), bottomBound)

                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        offset = CGSize(width: targetX, height: clampedY)
                        dragOffset = .zero
                        isDragging = false
                    }
                }
        )
        .highPriorityGesture(
            TapGesture()
                .onEnded {
                    // Only treat as tap if not dragging
                    guard !isDragging else { return }
                    isOpen = true
                }
        )
        .accessibilityLabel("Coach")
        .accessibilityHint("Drag to reposition. Tap to chat.")
    }
}

struct DraggableCoachBubble_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemBackground)
            DraggableCoachBubble(isOpen: .constant(false))
        }
    }
}
