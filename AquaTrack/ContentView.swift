import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WaterTrackerViewModel()
    @State private var customAmount: String = ""
    @State private var showingGoalSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: viewModel.progress)
                    
                    VStack {
                        Text("\(Int(viewModel.todaysIntake))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("of \(Int(viewModel.dailyGoal)) oz")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // Quick Add Buttons
                HStack(spacing: 16) {
                    QuickAddButton(amount: 8, viewModel: viewModel)
                    QuickAddButton(amount: 12, viewModel: viewModel)
                    QuickAddButton(amount: 16, viewModel: viewModel)
                }
                
                // Custom Amount
                HStack {
                    TextField("Custom oz", text: $customAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                    
                    Button("Add") {
                        if let amount = Double(customAmount), amount > 0 {
                            viewModel.addWater(amount: amount)
                            customAmount = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(customAmount.isEmpty)
                }
                
                // Today's Logs
                if !viewModel.entries.isEmpty {
                    List {
                        ForEach(viewModel.entries.reversed()) { entry in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(Int(entry.amount)) oz")
                                        .font(.headline)
                                    Text(entry.type)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(entry.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.removeEntry(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                } else {
                    Text("No water logged yet today. Start hydrating!")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("AquaTrack")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingGoalSheet = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingGoalSheet) {
                GoalSettingsView(viewModel: viewModel)
            }
        }
    }
}

struct QuickAddButton: View {
    let amount: Double
    @ObservedObject var viewModel: WaterTrackerViewModel
    
    var body: some View {
        Button {
            viewModel.addWater(amount: amount)
        } label: {
            VStack {
                Image(systemName: "drop.fill")
                    .font(.title2)
                Text("+\(Int(amount)) oz")
                    .font(.caption)
                    .bold()
            }
            .frame(width: 80, height: 80)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct GoalSettingsView: View {
    @ObservedObject var viewModel: WaterTrackerViewModel
    @Environment(\.dismiss) var dismiss
    @State private var goalText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Goal") {
                    TextField("Goal in ounces", text: $goalText)
                        .keyboardType(.decimalPad)
                    Button("Save") {
                        if let newGoal = Double(goalText) {
                            viewModel.updateGoal(newGoal)
                            dismiss()
                        }
                    }
                    .disabled(goalText.isEmpty)
                }
                Section {
                    Text("Current goal: \(Int(viewModel.dailyGoal)) oz")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                goalText = "\(Int(viewModel.dailyGoal))"
            }
        }
    }
}

#Preview {
    ContentView()
}
