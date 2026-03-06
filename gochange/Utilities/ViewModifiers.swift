import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            .shadow(color: Color.black.opacity(AppShadow.cardOpacity),
                    radius: AppShadow.cardRadius,
                    x: AppShadow.cardX,
                    y: AppShadow.cardY)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppBorder.color, lineWidth: AppBorder.width)
            )
    }
}

struct SubCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.miniRadius))
            .shadow(color: Color.black.opacity(AppShadow.subCardOpacity),
                    radius: AppShadow.subCardRadius,
                    x: 0,
                    y: AppShadow.subCardY)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.miniRadius)
                    .stroke(AppBorder.color, lineWidth: AppBorder.width)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func subCardStyle() -> some View {
        modifier(SubCardStyle())
    }
}
