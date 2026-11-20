import Foundation
import Combine

final class WaterTrackerViewModel: ObservableObject {
    static let minimumGoal = 16.0
    static let defaultGoal = 64.0

    @Published private(set) var entries: [WaterEntry] = []
    @Published private(set) var dailyGoal = WaterTrackerViewModel.defaultGoal

    private let entriesKey = "waterEntries"
    private let goalKey = "dailyGoal"
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date

    init(defaults: UserDefaults = .standard, calendar: Calendar = .autoupdatingCurrent, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.calendar = calendar
        self.now = now

        let savedGoal = defaults.double(forKey: goalKey)
        if savedGoal.isFinite, savedGoal >= Self.minimumGoal {
            dailyGoal = savedGoal
        }
        if let data = defaults.data(forKey: entriesKey),
           let savedEntries = try? JSONDecoder().decode([WaterEntry].self, from: data) {
            entries = savedEntries.filter { $0.amount > 0 && $0.amount.isFinite }
        }
        refreshDay()
    }

    var todaysIntake: Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    var progress: Double {
        min(todaysIntake / dailyGoal, 1)
    }

    @discardableResult
    func addWater(amount: Double, type: String = "Water") -> Bool {
        let date = now()
        refreshDay(at: date)
        guard amount.isFinite, amount > 0, (todaysIntake + amount).isFinite else { return false }
        entries.append(WaterEntry(amount: amount, type: type, timestamp: date))
        saveEntries()
        return true
    }

    func removeEntry(_ entry: WaterEntry) {
        refreshDay()
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    func updateGoal(_ newGoal: Double) {
        guard newGoal.isFinite, newGoal >= Self.minimumGoal else { return }
        dailyGoal = newGoal
        defaults.set(newGoal, forKey: goalKey)
    }

    func refreshDay() {
        refreshDay(at: now())
    }

    private func refreshDay(at date: Date) {
        let todaysEntries = entries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
        if todaysEntries.count != entries.count {
            entries = todaysEntries
            saveEntries()
        }
    }

    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: entriesKey)
        }
    }

    static func parseOunces(_ text: String, locale: Locale) -> Double? {
        let separator = locale.decimalSeparator ?? "."
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.unicodeScalars.allSatisfy({
            CharacterSet.decimalDigits.contains($0) || separator.unicodeScalars.contains($0)
        }) else { return nil }
        let normalized = trimmed.map { $0.wholeNumberValue.map(String.init) ?? String($0) }.joined()
            .replacingOccurrences(of: separator, with: ".")
        guard let value = Double(normalized), value.isFinite, value > 0 else { return nil }
        return value
    }
}
