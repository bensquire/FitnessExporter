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

                // MARK: HealthKit Authorization
                Section("HealthKit") {
                    if viewModel.isAuthorized {
                        Label("Authorized", systemImage: "checkmark.shield.fill")
                            .foregroundColor(.green)
                    } else {
                        if let error = viewModel.authorizationError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        Button("Authorize HealthKit Access") {
                            Task { await viewModel.requestAuthorization() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
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

                // MARK: HTTP Settings
                if viewModel.currentMode == .http {
                    Section("HTTP Settings") {
                        TextField("Endpoint URL", text: $viewModel.httpURL)
                            .textContentType(.URL)
                            .autocapitalization(.none)
                            .keyboardType(.URL)

                        if !viewModel.httpURL.isEmpty,
                            URL(string: viewModel.httpURL)?.scheme != "https"
                        {
                            Label(
                                "URL must use HTTPS", systemImage: "exclamationmark.triangle.fill"
                            )
                            .foregroundColor(.orange)
                            .font(.caption)
                        }

                        SecureField("Bearer Token (optional)", text: $viewModel.httpToken)
                    }
                }

                // MARK: File Settings
                if viewModel.currentMode == .file {
                    Section {
                        Text(
                            verbatim:
                                "Files saved to app Documents folder as \(Calendar.current.component(.year, from: Date())).json"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                                Label("\(count) records sent", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            case .failure(let error):
                                Label(error.message, systemImage: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .lineLimit(2)
                            }
                        }
                    }

                    Text("Sends 7 days of randomized mock data using your current export settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Test Export")
                }
            }
            .navigationTitle("Fitness Exporter")
        }
    }
}
