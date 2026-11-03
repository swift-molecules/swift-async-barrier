# swift-async-barrier

Use this package when a fixed number of parties must all reach a point before any of them continues, and parties may arrive either by awaiting or by registering a callback. Start from `Async.Barrier`.

## Laws

- The barrier is one-shot. It releases on the arrival that brings `arrived` up to `parties` minus `cancelledCount`, and it never resets.
- After release, every arrival, awaited or callback, proceeds immediately and is not counted in `arrived`.
- On release, the releasing arrival first resumes every suspended awaited arrival, in no particular order. It then runs the pending callbacks synchronously on its own thread, in arrival order, and runs its own callback last.
- Cancelling a suspended awaited arrival fails it with `Async.Lifecycle.Error.cancelled`. Its arrival is withdrawn from `arrived` and `cancelledCount` goes up by one, so one fewer party is needed from then on. The cancellation does not release the barrier by itself; the next arrival does.
- An awaited arrival from a task that is already cancelled succeeds if the barrier is already released. If the barrier is not released, it fails with `Async.Lifecycle.Error.cancelled`, is not counted and does not change `cancelledCount`. A cancellation that comes after release has no effect.
- Callback arrivals cannot be cancelled and always count.
