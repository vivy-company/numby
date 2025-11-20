#if os(macOS)
//
//  HistorySidebarView.swift
//  Numby
//
//  Sidebar view for calculator history with search
//

import SwiftUI
import AppKit

struct HistorySidebarView: View {
    @ObservedObject var historyManager: HistoryManager
    var onSessionSelected: ((CalculationSession) -> Void)?

    @State private var selectedSession: CalculationSession?
    @State private var editingSession: CalculationSession?
    @State private var editingName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $historyManager.searchQuery)
                .padding(8)

            Divider()

            // Session list
            if historyManager.filteredSessions.isEmpty {
                EmptyStateView(hasSearchQuery: !historyManager.searchQuery.isEmpty)
            } else {
                SessionList(
                    sessions: historyManager.filteredSessions,
                    selectedSession: $selectedSession,
                    editingSession: $editingSession,
                    editingName: $editingName,
                    historyManager: historyManager,
                    onSessionSelected: onSessionSelected
                )
            }
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 400)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    @State private var localeVersion: Int = 0

    private var localizedPlaceholder: String {
        _ = localeVersion
        return "history.searchPlaceholder".localized
    }

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(localizedPlaceholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LocaleChanged"))) { _ in
            localeVersion += 1
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let hasSearchQuery: Bool
    @State private var localeVersion: Int = 0

    private var localizedTitle: String {
        _ = localeVersion
        return hasSearchQuery ? "history.noResults".localized : "history.empty".localized
    }

    private var localizedDescription: String {
        _ = localeVersion
        return "history.emptyDescription".localized
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: hasSearchQuery ? "magnifyingglass" : "clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(localizedTitle)
                .font(.headline)
                .foregroundColor(.secondary)

            if !hasSearchQuery {
                Text(localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LocaleChanged"))) { _ in
            localeVersion += 1
        }
    }
}

// MARK: - Session List

struct SessionList: View {
    let sessions: [CalculationSession]
    @Binding var selectedSession: CalculationSession?
    @Binding var editingSession: CalculationSession?
    @Binding var editingName: String
    let historyManager: HistoryManager
    let onSessionSelected: ((CalculationSession) -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(sessions, id: \.id) { session in
                    SessionRow(
                        session: session,
                        isEditing: editingSession?.id == session.id,
                        editingName: $editingName,
                        historyManager: historyManager,
                        onEdit: { startEditing(session) },
                        onFinishEdit: { finishEditing(session) },
                        onDelete: { deleteSession(session) },
                        onSelect: { selectSession(session) }
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Group {
                            if selectedSession?.id == session.id {
                                Color(nsColor: NSColor.selectedContentBackgroundColor).opacity(0.35)
                                    .cornerRadius(8)
                            } else {
                                Color.clear
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private func startEditing(_ session: CalculationSession) {
        editingSession = session
        editingName = session.customName ?? ""
    }

    private func finishEditing(_ session: CalculationSession) {
        if !editingName.isEmpty {
            historyManager.updateSessionName(session: session, newName: editingName)
        }
        editingSession = nil
        editingName = ""
    }

    private func deleteSession(_ session: CalculationSession) {
        historyManager.deleteSession(session)
        if selectedSession?.id == session.id {
            selectedSession = nil
        }
    }

    private func selectSession(_ session: CalculationSession) {
        selectedSession = session
        onSessionSelected?(session)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: CalculationSession
    let isEditing: Bool
    @Binding var editingName: String
    let historyManager: HistoryManager
    let onEdit: () -> Void
    let onFinishEdit: () -> Void
    let onDelete: () -> Void
    let onSelect: () -> Void
    @State private var localeVersion: Int = 0

    private var localizedName: String {
        _ = localeVersion
        return "history.name".localized
    }

    private var localizedDone: String {
        _ = localeVersion
        return "history.done".localized
    }

    private var localizedOpenInNewTab: String {
        _ = localeVersion
        return "history.openInNewTab".localized
    }

    private var localizedRename: String {
        _ = localeVersion
        return "history.rename".localized
    }

    private var localizedDelete: String {
        _ = localeVersion
        return "history.delete".localized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isEditing {
                HStack {
                    TextField(localizedName, text: $editingName, onCommit: onFinishEdit)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(localizedDone) {
                        onFinishEdit()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(historyManager.displayName(for: session))
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)

                        if let preview = session.searchableText?.components(separatedBy: .newlines).first(where: { !$0.isEmpty }) {
                            Text(preview)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Text(formatTimestamp(session.swiftTimestamp))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect()
                }
                .contextMenu {
                    Button(localizedOpenInNewTab) {
                        onSelect()
                    }
                    Button(localizedRename) {
                        onEdit()
                    }
                    Divider()
                    Button(localizedDelete) {
                        onDelete()
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LocaleChanged"))) { _ in
            localeVersion += 1
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

struct HistorySidebarView_Previews: PreviewProvider {
    static var previews: some View {
        HistorySidebarView(
            historyManager: HistoryManager(context: PersistenceController.preview.container.viewContext)
        )
        .frame(width: 250, height: 600)
    }
}
#endif
