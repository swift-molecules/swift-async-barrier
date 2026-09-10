import Async
import Async_Barrier
import Testing

@Suite
struct `Async barriers coordinate arrivals and cancellation` {
    @Test
    func `Init creates unreleased barrier`() {
        let barrier = Async.Barrier(parties: 3)
        #expect(barrier.arrived == 0)
        #expect(!barrier.isReleased)
    }

    @Test
    func `Arrive() throws cancelled on mid-await cancellation`() async throws {

        let barrier = Async.Barrier(parties: 2)

        let cancellableTask = Task { () async -> Result<Void, Async.Lifecycle.Error> in
            do throws(Async.Lifecycle.Error) {
                try await barrier.arrive()
                return .success(())
            } catch {
                return .failure(error)
            }
        }

        try? await Task.sleep(for: .milliseconds(20))
        #expect(barrier.arrived == 1, "first party arrived and is suspended")

        cancellableTask.cancel()

        try? await Task.sleep(for: .milliseconds(20))

        let firstResult = await cancellableTask.value
        if case .failure(.cancelled) = firstResult {

        } else {
            Issue.record("expected .failure(.cancelled), got \(firstResult)")
        }
        #expect(barrier.cancelledCount == 1, "cancellation count incremented")

        try await barrier.arrive()
        #expect(barrier.isReleased, "barrier releases on effective party count met")
        #expect(barrier.arrived == 1, "arrived rolled back the cancelled party")
    }

    @Test
    func `Single party barrier releases immediately`() {
        let barrier = Async.Barrier(parties: 1)

        let publication = Async.Publication<Bool>()
        barrier.arrive {
            publication.publish(true)
        }
        #expect(publication.take() == true)
        #expect(barrier.isReleased)
        #expect(barrier.arrived == 1)
    }

    @Test
    func `Multi party barrier waits for all arrivals`() {
        let barrier = Async.Barrier(parties: 3)

        let pub1 = Async.Publication<Bool>()
        let pub2 = Async.Publication<Bool>()
        let pub3 = Async.Publication<Bool>()

        barrier.arrive { pub1.publish(true) }
        #expect(pub1.take() == nil)
        #expect(barrier.arrived == 1)
        #expect(!barrier.isReleased)

        barrier.arrive { pub2.publish(true) }
        #expect(pub2.take() == nil)
        #expect(barrier.arrived == 2)
        #expect(!barrier.isReleased)

        barrier.arrive { pub3.publish(true) }
        #expect(pub1.take() == true)
        #expect(pub2.take() == true)
        #expect(pub3.take() == true)
        #expect(barrier.arrived == 3)
        #expect(barrier.isReleased)
    }

    @Test
    func `Arrive after release invokes callback immediately`() {
        let barrier = Async.Barrier(parties: 1)
        barrier.arrive {}

        let publication = Async.Publication<Bool>()
        barrier.arrive { publication.publish(true) }
        #expect(publication.take() == true)
    }

    #if !hasFeature(Embedded)
        @Test
        func `Async arrive releases when all parties arrive`() async {
            let barrier = Async.Barrier(parties: 3)

            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<3 {
                    group.addTask {
                        try? await barrier.arrive()
                    }
                }
            }

            #expect(barrier.isReleased)
            #expect(barrier.arrived == 3)
        }
    #endif
}
