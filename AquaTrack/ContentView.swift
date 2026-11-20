import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WaterTrackerViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var editingAmount: Bool
    @State private var customAmount = ""
    @State private var showingGoalSheet = false
    @State private var showingAmountError = false

    private var amount: Double? { WaterTrackerViewModel.parseOunces(customAmount, locale: locale) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 20) {
                        progressRing
                        quickActions
                        customInput
                    }
                    .frame(maxWidth: 500)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                }
                Section("Today’s Log") {
                    if viewModel.entries.isEmpty {
                        Text("Add a drink to start today’s log.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.entries.reversed()) { entry in
                            logRow(entry)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("AquaTrack")
            .toolbar {
                Button("Settings", systemImage: "gear") { showingGoalSheet = true }
                    .accessibilityIdentifier("water.settings")
            }
            .sheet(isPresented: $showingGoalSheet) {
                GoalSettingsView(viewModel: viewModel)
            }
            .alert("Amount Couldn’t Be Added", isPresented: $showingAmountError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enter a smaller amount and try again.")
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refreshDay() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            viewModel.refreshDay()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            viewModel.refreshDay()
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle().strokeBorder(.blue.opacity(0.14), lineWidth: 14)
            Circle()
                .inset(by: 7)
                .trim(from: 0, to: viewModel.progress)
                .stroke(.blue.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeInOut, value: viewModel.progress)
            VStack(spacing: 3) {
                Image(systemName: "drop.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                Text(viewModel.todaysIntake, format: .number)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .accessibilityLabel("\(viewModel.todaysIntake, format: .number) ounces logged today")
                    .accessibilityIdentifier("water.total")
                    .lineLimit(1)
                Text("of \(viewModel.dailyGoal, format: .number) oz")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Daily goal \(viewModel.dailyGoal, format: .number) ounces")
                    .accessibilityIdentifier("water.goal")
                    .lineLimit(1)
            }
            .padding(22)
            .minimumScaleFactor(0.5)
        }
        .frame(width: 185, height: 185)
    }

    private var quickActions: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 10))
        return layout {
            ForEach([8, 12, 16], id: \.self) { amount in
                Button {
                    if !viewModel.addWater(amount: Double(amount)) {
                        showingAmountError = true
                    }
                } label: {
                    Text("+\(amount) oz")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.blue)
                .accessibilityLabel("Add \(amount) ounces")
                .accessibilityIdentifier("water.add.\(amount)")
            }
        }
    }

    private var customInput: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 10))
        return layout {
            TextField("Custom amount (oz)", text: $customAmount)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .focused($editingAmount)
                .accessibilityIdentifier("water.amount")

            Button("Add") {
                guard let amount else { return }
                if viewModel.addWater(amount: amount) {
                    customAmount = ""
                    editingAmount = false
                } else {
                    showingAmountError = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(amount == nil)
            .accessibilityIdentifier("water.add.custom")
        }
    }

    private func logRow(_ entry: WaterEntry) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(entry.amount, format: .number) oz")
                    .font(.headline)
                Text(entry.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.timestamp, style: .time)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive) {
                viewModel.removeEntry(entry)
            }
        }
        .accessibilityAction(named: Text("Delete Entry")) {
            viewModel.removeEntry(entry)
        }
    }
}

struct GoalSettingsView: View {
    @ObservedObject var viewModel: WaterTrackerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var goalText = ""

    private var goal: Double? { WaterTrackerViewModel.parseOunces(goalText, locale: locale) }
    private var validGoal: Bool { (goal ?? 0) >= WaterTrackerViewModel.minimumGoal }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Daily goal in ounces", text: $goalText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("water.goal.input")
                } header: {
                    Text("Daily Goal")
                } footer: {
                    Text("Enter a goal of at least \(WaterTrackerViewModel.minimumGoal, format: .number) oz.")
                }
                Section {
                    Link("Support", destination: URL(string: "https://ai2life.org/support/aquatrack")!)
                    Link("Privacy Policy", destination: URL(string: "https://ai2life.org/aquatrack/privacy")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let goal, validGoal else { return }
                        viewModel.updateGoal(goal)
                        dismiss()
                    }
                    .disabled(!validGoal)
                    .accessibilityIdentifier("water.goal.save")
                }
            }
            .onAppear {
                goalText = viewModel.dailyGoal.formatted(.number.locale(locale).grouping(.never))
            }
        }
    }
}

#Preview {
    ContentView()
}
