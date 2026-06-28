import SwiftUI

/// Single filter + sort sheet shared by every list (spec §9.3). Filters compose
/// and can be reset; unknown-data entries are handled by FilterEngine.
struct FilterSheet: View {
    @Binding var criteria: FilterCriteria
    let availableCountries: [String]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sort") {
                    Picker("Order", selection: $criteria.sort) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if let metricLabel = TopicConfig.metricLabel {
                    Section(metricLabel.capitalized) {
                        Picker("Minimum", selection: $criteria.minMetric) {
                            Text("Any").tag(Int?.none)
                            ForEach(TopicConfig.metricThresholds, id: \.self) { value in
                                Text("\(value)+").tag(Int?.some(value))
                            }
                        }
                        Text("Entries without a recorded \(metricLabel) are hidden when a minimum is set.")
                            .font(.caption)
                            .foregroundStyle(Palette.labelSecondary)
                    }
                }

                if TopicConfig.showRegionFilter, !availableCountries.isEmpty {
                    Section("Region") {
                        ForEach(availableCountries, id: \.self) { country in
                            Button {
                                toggleCountry(country)
                            } label: {
                                HStack {
                                    Text(country).foregroundStyle(Palette.labelPrimary)
                                    Spacer()
                                    if criteria.countries.contains(country) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Palette.accent)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { criteria = FilterCriteria(searchText: criteria.searchText) }
                        .disabled(!criteria.isActive)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggleCountry(_ country: String) {
        if criteria.countries.contains(country) {
            criteria.countries.remove(country)
        } else {
            criteria.countries.insert(country)
        }
    }
}
