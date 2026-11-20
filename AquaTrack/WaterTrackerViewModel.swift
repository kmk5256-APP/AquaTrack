import Foundation
import Combine

class WaterTrackerViewModel: ObservableObject {
    @Published var entries: [WaterEntry] = []
    @Published var dailyGoal: Double = 64.0 // ounces
    
    private let entriesKey = "waterEntries"
    private let goalKey = "dailyGoal"
    private let lastResetKey = "lastResetDate"
    
    init() {
        loadData()
        checkDailyReset()
    }
    
    var todaysIntake: Double {
        entries.reduce(0) { $0 + $1.amount }
    }
    
    var progress: Double {
        min(todaysIntake / dailyGoal, 1.0)
    }
    
    func addWater(amount: Double, type: String = "Water") {
        let entry = WaterEntry(amount: amount, type: type)
        entries.append(entry)
        saveData()
    }
    
    func removeEntry(_ entry: WaterEntry) {
        entries.removeAll { $0.id == entry.id }
        saveData()
    }
    
    func updateGoal(_ newGoal: Double) {
        dailyGoal = max(16, newGoal)
        UserDefaults.standard.set(dailyGoal, forKey: goalKey)
    }
    
    private func checkDailyReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastReset = UserDefaults.standard.object(forKey: lastResetKey) as? Date {
            if !calendar.isDate(lastReset, inSameDayAs: today) {
                entries = []
                UserDefaults.standard.set(today, forKey: lastResetKey)
                saveData()
            }
        } else {
            UserDefaults.standard.set(today, forKey: lastResetKey)
        }
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([WaterEntry].self, from: data) {
            entries = decoded
        }
        dailyGoal = UserDefaults.standard.double(forKey: goalKey)
        if dailyGoal == 0 { dailyGoal = 64.0 }
    }
}
