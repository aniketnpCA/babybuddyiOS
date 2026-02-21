import SwiftUI

struct AIChatSheet: View {
    let viewModel: AnalyticsViewModel
    let childAge: String
    let childID: Int

    @Environment(\.dismiss) private var dismiss
    @State private var aiViewModel = AIViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    private let suggestedQuestions = [
        "How are the feeding patterns looking?",
        "Is the sleep schedule healthy?",
        "Any concerns about growth?",
        "How do diaper changes compare to expected?",
        "What trends do you notice this week?",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !aiViewModel.isConfigured {
                    notConfiguredView
                } else {
                    chatContent
                    Divider()
                    inputBar
                }
            }
            .navigationTitle("Ask AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if aiViewModel.isConfigured && !aiViewModel.messages.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Clear") {
                            aiViewModel.clearConversation()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Not Configured View

    private var notConfiguredView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("AI Not Configured")
                .font(.title2.bold())
            Text("Add your OpenAI-compatible API key in Settings to use AI-powered analytics.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if aiViewModel.messages.isEmpty {
                        welcomeView
                    }

                    ForEach(aiViewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if aiViewModel.isLoading {
                        HStack {
                            ProgressView()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("loading")
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: aiViewModel.messages.count) {
                withAnimation {
                    if let lastMessage = aiViewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: aiViewModel.isLoading) {
                if aiViewModel.isLoading {
                    withAnimation {
                        proxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.purple)
                Text("Ask anything about your baby's data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            VStack(spacing: 8) {
                ForEach(suggestedQuestions, id: \.self) { question in
                    Button {
                        sendQuestion(question)
                    } label: {
                        Text(question)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask a question...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onSubmit {
                    if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        sendQuestion(inputText)
                    }
                }

            Button {
                sendQuestion(inputText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !aiViewModel.isLoading
    }

    private func sendQuestion(_ question: String) {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        inputText = ""
        let context = viewModel.buildAIContext(childAge: childAge)

        Task {
            await aiViewModel.ask(question: trimmed, context: context)
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: AIMessage

    private var contentText: Text {
        if message.role == .assistant,
           let attributed = try? AttributedString(
               markdown: message.content,
               options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
           ) {
            return Text(attributed)
        }
        return Text(message.content)
    }

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                contentText
                    .font(.body)
                    .textSelection(.enabled)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.role == .user
                    ? AnyShapeStyle(Color.blue)
                    : AnyShapeStyle(.ultraThinMaterial)
            )
            .foregroundStyle(message.role == .user ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal)
    }
}
