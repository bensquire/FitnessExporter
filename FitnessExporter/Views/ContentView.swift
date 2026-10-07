import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Status
                Section("Status") {
                    StatusSummaryView(viewModel: viewModel)

                    Button {
                        Task { await viewModel.exportNow() }
                    } label: {
                        Label("Export Now", systemImage: "square.and.arrow.up")
                    }
                    .disabled(viewModel.isExporting)
                }

                // MARK: Health Access
                Section {
                    if viewModel.hasRequestedHealthAccess {
                        Label("Access requested", systemImage: "checkmark.shield")
                    } else {
                        if let error = viewModel.authorizationError {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        Button("Request Health Access") {
                            Task { await viewModel.requestAuthorization() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } header: {
                    Text("Health")
                } footer: {
                    Text(
                        "Health doesn't tell apps which data you let them read. To check or change it, "
                            + "look for Fitness Exporter in Settings or the Health app."
                    )
                }

                // MARK: Export Mode
                Section("Export Mode") {
                    Picker("Mode", selection: $viewModel.exportMode) {
                        ForEach(ExportMode.allCases, id: \.rawValue) { mode in
                            Text(mode.displayName)
                                .tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: Mode Settings
                switch viewModel.currentMode {
                case .http:
                    Section("HTTP Settings") {
                        TextField("Endpoint URL", text: $viewModel.httpURL)
                            .textContentType(.URL)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)

                        if viewModel.httpURLWillBeRefused {
                            Label(
                                "URL must use HTTPS", systemImage: "exclamationmark.triangle.fill"
                            )
                            .foregroundStyle(.orange)
                            .font(.caption)
                        }

                        SecureField("Bearer Token (optional)", text: $viewModel.httpToken)

                        if let error = viewModel.tokenSaveError {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }

                case .file:
                    Section {
                        Text(
                            verbatim:
                                "Each year is saved as its own file, such as "
                                + "\(Calendar.current.component(.year, from: Date())).json, "
                                + "in the app's Documents folder."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } header: {
                        Text("File Settings")
                    } footer: {
                        Text(
                            "Access exported files via the Files app → On My iPhone → Fitness Exporter."
                        )
                    }
                }

                // MARK: Lookback
                Section("Data Range") {
                    Picker("Lookback", selection: $viewModel.lookbackDaysRaw) {
                        ForEach(LookbackPeriod.allCases, id: \.rawValue) { period in
                            Text(period.displayName).tag(period.rawValue)
                        }
                    }
                }

                // MARK: Test Export
                Section {
                    HStack {
                        Button(viewModel.isTestExporting ? "Sending…" : "Send Mock Data") {
                            Task { await viewModel.sendTestExport() }
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isTestExporting)

                        Spacer()

                        if let result = viewModel.testExportResult {
                            switch result {
                            case .success(_, let count):
                                Label("\(count) days exported", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            case .failure(let error):
                                Label(error.message, systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                    .lineLimit(2)
                            }
                        }
                    }

                    Text("Sends 7 days of randomized mock data using your current export settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Test Export")
                }
            }
            .navigationTitle("Fitness Exporter")
            .task { await viewModel.refreshHealthAccessState() }
        }
    }
}
