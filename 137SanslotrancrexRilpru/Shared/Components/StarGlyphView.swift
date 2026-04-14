import SwiftUI

struct StarGlyphView: View {
    var filled: Bool
    var glow: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 * 0.9
            var path = Path()
            let points = 5
            for i in 0..<(points * 2) {
                let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
                let r = i.isMultiple(of: 2) ? radius : radius * 0.45
                let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
                if i == 0 {
                    path.move(to: pt)
                } else {
                    path.addLine(to: pt)
                }
            }
            path.closeSubpath()

            if glow && filled {
                context.addFilter(.shadow(color: Color.appAccent.opacity(0.9), radius: 8, x: 0, y: 0))
            }

            context.fill(path, with: .color(filled ? Color.appPrimary : Color.appSurface))
            context.stroke(path, with: .color(Color.appAccent.opacity(filled ? 0.35 : 0.6)), lineWidth: 1.5)
        }
        .accessibilityLabel(filled ? "Star earned" : "Star locked")
    }
}
