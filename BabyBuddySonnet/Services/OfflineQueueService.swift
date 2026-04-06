import Foundation
import Network

// MARK: - Queued Operation Model

nonisolated enum QueuedOperationType: String, Codable, Sendable {
    case create
    case update
    case delete
}

nonisolated enum QueuedEntityType: String, Codable, Sendable {
    case feeding
    case pumping
    case sleep
    case diaper
    case tummyTime
    case temperature
    case note
    case timer
}

nonisolated struct QueuedOperation: Codable, Identifiable, Sendable {
    let id: String
    let operationType: QueuedOperationType
    let entityType: QueuedEntityType
    let path: String
    let body: Data?
    let httpMethod: String
    let createdAt: Date
    var retryCount: Int
    var lastError: String?
    var status: QueuedOperationStatus

    init(
        operationType: QueuedOperationType,
        entityType: QueuedEntityType,
        path: String,
        body: Data?,
        httpMethod: String
    ) {
        self.id = UUID().uuidString
        self.operationType = operationType
        self.entityType = entityType
        self.path = path
        self.body = body
        self.httpMethod = httpMethod
        self.createdAt = Date()
        self.retryCount = 0
        self.lastError = nil
        self.status = .pending
    }
}

nonisolated enum QueuedOperationStatus: String, Codable, Sendable {
    case pending
    case syncing
    case failed
}

// MARK: - Offline Queue Service

@Observable
@MainActor
final class OfflineQueueService {
    static let shared = OfflineQueueService()

    private(set) var queue: [QueuedOperation] = []
    private(set) var isOnline = true
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.babybuddy.networkMonitor")
    private let storageKey = "offlineQueue"
    private let maxRetries = 3

    var pendingCount: Int {
        queue.filter { $0.status != .failed || $0.retryCount < maxRetries }.count
    }

    var failedCount: Int {
        queue.filter { $0.status == .failed && $0.retryCount >= maxRetries }.count
    }

    var hasPendingOperations: Bool {
        !queue.isEmpty
    }

    private init() {
        loadQueue()
        startMonitoring()
    }

    // MARK: - Network Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                let wasOffline = !self.isOnline
                self.isOnline = path.status == .satisfied
                if wasOffline && self.isOnline {
                    await self.processQueue()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Enqueue Operations

    func enqueue<T: Encodable & Sendable>(
        operationType: QueuedOperationType,
        entityType: QueuedEntityType,
        path: String,
        body: T?,
        httpMethod: String
    ) {
        let bodyData: Data?
        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            bodyData = try? encoder.encode(body)
        } else {
            bodyData = nil
        }

        let op = QueuedOperation(
            operationType: operationType,
            entityType: entityType,
            path: path,
            body: bodyData,
            httpMethod: httpMethod
        )
        queue.append(op)
        saveQueue()

        if isOnline {
            Task {
                await processQueue()
            }
        }
    }

    func enqueueDelete(entityType: QueuedEntityType, path: String) {
        let op = QueuedOperation(
            operationType: .delete,
            entityType: entityType,
            path: path,
            body: nil,
            httpMethod: "DELETE"
        )
        queue.append(op)
        saveQueue()

        if isOnline {
            Task {
                await processQueue()
            }
        }
    }

    // MARK: - Process Queue

    func processQueue() async {
        guard isOnline else { return }

        var indicesToRemove: [Int] = []

        for i in queue.indices {
            guard queue[i].status != .failed || queue[i].retryCount < maxRetries else { continue }

            queue[i].status = .syncing
            saveQueue()

            do {
                try await executeOperation(queue[i])
                indicesToRemove.append(i)
            } catch {
                queue[i].retryCount += 1
                queue[i].lastError = error.localizedDescription
                if queue[i].retryCount >= maxRetries {
                    queue[i].status = .failed
                } else {
                    queue[i].status = .pending
                }
                saveQueue()
            }
        }

        // Remove successfully synced operations (in reverse order to preserve indices)
        for i in indicesToRemove.reversed() {
            if i < queue.count {
                queue.remove(at: i)
            }
        }
        saveQueue()
    }

    private func executeOperation(_ op: QueuedOperation) async throws {
        switch op.httpMethod {
        case "POST":
            guard let body = op.body else { throw APIError.invalidURL }
            let _: IgnoredResponse = try await APIClient.shared.postRaw(path: op.path, body: body)
        case "PATCH":
            guard let body = op.body else { throw APIError.invalidURL }
            let _: IgnoredResponse = try await APIClient.shared.patchRaw(path: op.path, body: body)
        case "DELETE":
            try await APIClient.shared.delete(path: op.path)
        default:
            break
        }
    }

    // MARK: - Remove Failed Operations

    func removeOperation(id: String) {
        queue.removeAll { $0.id == id }
        saveQueue()
    }

    func retryFailed() async {
        for i in queue.indices where queue[i].status == .failed {
            queue[i].status = .pending
            queue[i].retryCount = 0
            queue[i].lastError = nil
        }
        saveQueue()
        await processQueue()
    }

    // MARK: - Persistence

    private func saveQueue() {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([QueuedOperation].self, from: data)
        else { return }
        queue = saved
    }
}

/// Placeholder decodable for fire-and-forget API calls from the queue
nonisolated struct IgnoredResponse: Decodable, Sendable {}

// MARK: - Convenience: Try API or Queue

extension OfflineQueueService {
    /// Attempt a POST; on network failure, enqueue for later.
    /// Returns true if the call succeeded immediately, false if queued.
    func tryPost<T: Encodable & Sendable>(
        entityType: QueuedEntityType,
        path: String,
        body: T
    ) async throws -> Bool {
        do {
            let _: IgnoredResponse = try await APIClient.shared.post(path: path, body: body)
            return true
        } catch let error as APIError {
            if case .networkError = error {
                enqueue(operationType: .create, entityType: entityType, path: path, body: body, httpMethod: "POST")
                return false
            }
            throw error
        } catch let error as URLError {
            enqueue(operationType: .create, entityType: entityType, path: path, body: body, httpMethod: "POST")
            if error.code == .cancelled { throw error }
            return false
        }
    }

    /// Attempt a PATCH; on network failure, enqueue for later.
    func tryPatch<T: Encodable & Sendable>(
        entityType: QueuedEntityType,
        path: String,
        body: T
    ) async throws -> Bool {
        do {
            let _: IgnoredResponse = try await APIClient.shared.patch(path: path, body: body)
            return true
        } catch let error as APIError {
            if case .networkError = error {
                enqueue(operationType: .update, entityType: entityType, path: path, body: body, httpMethod: "PATCH")
                return false
            }
            throw error
        } catch let error as URLError {
            enqueue(operationType: .update, entityType: entityType, path: path, body: body, httpMethod: "PATCH")
            if error.code == .cancelled { throw error }
            return false
        }
    }

    /// Attempt a DELETE; on network failure, enqueue for later.
    func tryDelete(
        entityType: QueuedEntityType,
        path: String
    ) async throws -> Bool {
        do {
            try await APIClient.shared.delete(path: path)
            return true
        } catch let error as APIError {
            if case .networkError = error {
                enqueueDelete(entityType: entityType, path: path)
                return false
            }
            throw error
        } catch let error as URLError {
            enqueueDelete(entityType: entityType, path: path)
            if error.code == .cancelled { throw error }
            return false
        }
    }
}
