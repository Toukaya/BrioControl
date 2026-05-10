//
//  UVCDeviceActorTests.swift
//  CameraControllerTests
//
//  Verifies the serialization behavior of UVCDeviceActor's reentrancy.
//  We cannot construct a real UVCDeviceActor from XCTest because it
//  requires an attached USB camera and an IOKit interface pointer; what
//  we *can* test is the actor model itself: that submitting many
//  concurrent setX calls observes a sequential ordering and that the
//  final value matches the last submitted write.
//
//  The test uses a stand-in actor with the same shape as UVCDeviceActor
//  (a stored value protected by actor isolation) to assert the lost-
//  update race that motivated TASK-07 cannot reoccur once writes are
//  funneled through an actor.
//

import XCTest

private actor SerializingValueStore {
    private(set) var current: Int = 0
    private(set) var observedSequence: [Int] = []

    func set(_ value: Int) {
        // The two-step write below is the canonical example of a
        // lost-update race in non-actor code: a read-modify-write that
        // would interleave when called from multiple tasks. Inside an
        // actor, isolation guarantees these two statements run as one
        // logical step per call.
        let previous = self.current
        self.current = value
        self.observedSequence.append(previous)
    }
}

final class UVCDeviceActorTests: XCTestCase {

    /// Submitting N concurrent set(_:) calls against an actor must
    /// produce exactly N entries in the observed sequence (no lost
    /// writes) and the final stored value must equal the last value
    /// that was actually accepted. Because actors do not guarantee FIFO
    /// over the suspension points of unstructured Tasks, we cannot
    /// assert ordering -- only completeness and the absence of races.
    func testActorSerializesConcurrentWrites() async {
        let store = SerializingValueStore()
        let writeCount = 1000

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<writeCount {
                group.addTask {
                    await store.set(index)
                }
            }
        }

        let observed = await store.observedSequence
        XCTAssertEqual(observed.count, writeCount,
                       "Actor lost \(writeCount - observed.count) writes")

        // The accepted final value must be one of the values we
        // submitted (i.e. no torn write or memory corruption).
        let final = await store.current
        XCTAssertGreaterThanOrEqual(final, 0)
        XCTAssertLessThan(final, writeCount)
    }

    /// When writes are submitted from a single sequential context (the
    /// pattern used by SwiftUI binding drag updates after task-07),
    /// awaiting them in submission order guarantees the actor's final
    /// state matches the last submitted value.
    func testSequentialAwaitedWritesPreserveOrder() async {
        let store = SerializingValueStore()
        for index in 0..<100 {
            await store.set(index)
        }

        let final = await store.current
        XCTAssertEqual(final, 99,
                       "Sequential awaited writes must converge on last value")

        let observed = await store.observedSequence
        XCTAssertEqual(observed.count, 100)
    }
}
