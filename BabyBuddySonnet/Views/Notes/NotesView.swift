import SwiftUI

struct NotesView: View {
    let childID: Int
    @State private var viewModel = NotesViewModel()
    @State private var showForm = false
    @State private var selectedTab = 0
    @State private var editingNote: Note?
    @State private var customStart: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customEnd: Date = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let error = viewModel.error {
                        ErrorBannerView(message: error) {
                            viewModel.error = nil
                        }
                    }

                    Picker("Period", selection: $selectedTab) {
                        Text("Today").tag(0)
                        Text("This Week").tag(1)
                        Text("Custom").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 {
                        todayContent
                    } else if selectedTab == 1 {
                        weekContent
                    } else {
                        customContent
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Notes")
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton(color: .jayNotesFallback) {
                    showForm = true
                }
            }
            .sheet(isPresented: $showForm) {
                NoteFormSheet(childID: childID) {
                    await reloadAll()
                }
            }
            .sheet(item: $editingNote) { note in
                NoteFormSheet(childID: childID, editing: note) {
                    await reloadAll()
                }
            }
            .refreshable {
                await reloadAll()
            }
            .task {
                await viewModel.loadToday(childID: childID)
                await viewModel.loadWeek(childID: childID)
            }
        }
    }

    private func reloadAll() async {
        await viewModel.loadToday(childID: childID)
        await viewModel.loadWeek(childID: childID)
        if selectedTab == 2 {
            await viewModel.loadCustomRange(childID: childID, start: customStart, end: customEnd)
        }
    }

    @ViewBuilder
    private var todayContent: some View {
        if viewModel.isLoadingToday {
            LoadingView()
        } else if viewModel.todayNotes.isEmpty {
            EmptyStateView(icon: "note.text", title: "No notes today", subtitle: "Tap + to add a note")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.todayNotes) { note in
                    Button { editingNote = note } label: {
                        NoteRowView(note: note)
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading)
                }
            }
        }
    }

    @ViewBuilder
    private var weekContent: some View {
        if viewModel.isLoadingWeek {
            LoadingView()
        } else {
            let grouped = Calculations.groupByDate(viewModel.weekNotes) { $0.time }
            ForEach(grouped, id: \.key) { group in
                DisclosureGroup {
                    ForEach(group.items) { note in
                        Button { editingNote = note } label: {
                            NoteRowView(note: note)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } label: {
                    HStack {
                        Text(group.key)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(group.items.count) notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var customContent: some View {
        VStack(spacing: 12) {
            HStack {
                DatePicker("From", selection: $customStart, displayedComponents: .date)
                    .labelsHidden()
                Text("to")
                    .foregroundStyle(.secondary)
                DatePicker("To", selection: $customEnd, displayedComponents: .date)
                    .labelsHidden()
                Button("Search") {
                    Task { await viewModel.loadCustomRange(childID: childID, start: customStart, end: customEnd) }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            if viewModel.isLoadingCustom {
                LoadingView()
            } else if viewModel.customNotes.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "No results", subtitle: "Try a different date range")
            } else {
                let grouped = Calculations.groupByDate(viewModel.customNotes) { $0.time }
                ForEach(grouped, id: \.key) { group in
                    DisclosureGroup {
                        ForEach(group.items) { note in
                            Button { editingNote = note } label: {
                                NoteRowView(note: note)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        HStack {
                            Text(group.key)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(group.items.count) notes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
