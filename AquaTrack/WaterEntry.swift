import Foundation

struct WaterEntry: Identifiable, Codable {
    let id: UUID
    let amount: Double // in ounces
    let timestamp: Date
    let type: String
    
    init(amount: Double, type: String = "Water", timestamp: Date = .now) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = timestamp
        self.type = type
    }
}
