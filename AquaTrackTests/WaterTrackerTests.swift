import Foundation
import XCTest
@testable import AquaTrack

final class WaterTrackerTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    func testEntriesAndGoalSurviveRelaunch() throws {
        let (defaults, domain) = try testDefaults()
        defer { defaults.removePersistentDomain(forName: domain) }

        let store = makeStore(defaults, now: { self.date(day: 8, hour: 9) })
        store.addWater(amount: 8)
        store.addWater(amount: 2.5)
        store.updateGoal(80.5)

        let relaunched = makeStore(defaults, now: { self.date(day: 8, hour: 10) })
        XCTAssertEqual(relaunched.todaysIntake, 10.5)
        XCTAssertEqual(relaunched.dailyGoal, 80.5)
        XCTAssertEqual(relaunched.progress, 10.5 / 80.5, accuracy: 0.0001)
        XCTAssertEqual(relaunched.entries.map(\.id), store.entries.map(\.id))
    }

    func testMidnightClearsEarlierEntriesWhileAppRemainsOpen() throws {
        let (defaults, domain) = try testDefaults()
        defer { defaults.removePersistentDomain(forName: domain) }
        var now = date(day: 7, hour: 23)
        let store = makeStore(defaults, now: { now })
        store.addWater(amount: 24)
        store.updateGoal(90)

        now = date(day: 8, hour: 0)
        store.refreshDay()
        XCTAssertTrue(store.entries.isEmpty)
        XCTAssertEqual(store.dailyGoal, 90)
        XCTAssertTrue(store.addWater(amount: 8))
        XCTAssertEqual(store.todaysIntake, 8)
        XCTAssertEqual(makeStore(defaults, now: { now }).todaysIntake, 8)
    }

    func testLoggingAfterMidnightDropsYesterdayEvenWithoutARefresh() throws {
        let (defaults, domain) = try testDefaults()
        defer { defaults.removePersistentDomain(forName: domain) }
        var now = date(day: 7, hour: 23)
        let store = makeStore(defaults, now: { now })
        store.addWater(amount: 16)

        now = date(day: 8, hour: 7)
        store.addWater(amount: 8)
        XCTAssertEqual(store.todaysIntake, 8)
    }

    func testDeletionPersistsAndRingStopsAtFull() throws {
        let (defaults, domain) = try testDefaults()
        defer { defaults.removePersistentDomain(forName: domain) }
        let now = { self.date(day: 8, hour: 12) }
        let store = makeStore(defaults, now: now)
        store.addWater(amount: 64)
        store.addWater(amount: 16)

        XCTAssertEqual(store.progress, 1)
        store.removeEntry(try XCTUnwrap(store.entries.first))
        XCTAssertEqual(makeStore(defaults, now: now).todaysIntake, 16)
    }

    func testInvalidAndOverflowingValuesAreRejected() throws {
        let (defaults, domain) = try testDefaults()
        defer { defaults.removePersistentDomain(forName: domain) }
        let store = makeStore(defaults, now: { self.date(day: 8, hour: 12) })

        for invalid in [0, -1, .infinity, .nan] {
            XCTAssertFalse(store.addWater(amount: invalid))
            store.updateGoal(invalid)
        }
        store.updateGoal(15)
        XCTAssertEqual(store.dailyGoal, 64)
        XCTAssertTrue(store.addWater(amount: .greatestFiniteMagnitude))
        XCTAssertFalse(store.addWater(amount: .greatestFiniteMagnitude))
        XCTAssertTrue(store.todaysIntake.isFinite)
    }

    func testDecimalInputUsesLocaleAndRejectsInvalidText() {
        let french = Locale(identifier: "fr_FR")
        XCTAssertEqual(WaterTrackerViewModel.parseOunces(" 2,5 ", locale: french), 2.5)
        XCTAssertNil(WaterTrackerViewModel.parseOunces("2,5 oz", locale: french))
        XCTAssertNil(WaterTrackerViewModel.parseOunces("1,2,3", locale: french))
        XCTAssertNil(WaterTrackerViewModel.parseOunces("0", locale: french))

        let arabic = Locale(identifier: "ar_SA")
        let separator = arabic.decimalSeparator ?? "."
        XCTAssertEqual(WaterTrackerViewModel.parseOunces("٢\(separator)٥", locale: arabic), 2.5)

        let english = Locale(identifier: "en_US")
        XCTAssertEqual(WaterTrackerViewModel.parseOunces("2.5", locale: english), 2.5)
        XCTAssertNil(WaterTrackerViewModel.parseOunces("Infinity", locale: english))
    }

    private func makeStore(_ defaults: UserDefaults, now: @escaping () -> Date) -> WaterTrackerViewModel {
        WaterTrackerViewModel(defaults: defaults, calendar: calendar, now: now)
    }

    private func testDefaults() throws -> (UserDefaults, String) {
        let domain = "org.ai2life.aquatrack.tests.\(UUID().uuidString)"
        return (try XCTUnwrap(UserDefaults(suiteName: domain)), domain)
    }

    private func date(day: Int, hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour))!
    }
}
