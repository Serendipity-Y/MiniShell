//
//  ConnectionRowView.swift
//  macSCP
//
//  List row for the connection list column
//

import SwiftUI

struct ConnectionRowView: View {
    let connection: Connection

    private let iconColor = Color.blue
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: connection.iconName)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 28, alignment: .center)

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(connection.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                // Connection string
                Text(connection.connectionString)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Tags
                if !connection.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(connection.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(.quaternary, in: Capsule())
                        }
                        if connection.tags.count > 3 {
                            Text("+\(connection.tags.count - 3)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.top, 1)
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(isHovering ? Color.white.opacity(0.22) : .clear, lineWidth: 1)
        }
        .scaleEffect(isHovering ? 1.012 : 1)
        .shadow(
            color: isHovering ? .black.opacity(0.22) : .clear,
            radius: isHovering ? 5 : 0,
            y: isHovering ? 2 : 0
        )
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.14), value: isHovering)
    }

    private var rowBackground: Color {
        isHovering ? Color.white.opacity(0.14) : .clear
    }
}
