import SwiftUI

struct StatusSummaryView: View {
    @ObservedObject var viewModel: AppViewModel

    private let relativeDateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private var lastExportText: String {
        guard let date = viewModel.lastExportDate else { return "Never" }
        return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }

    private var resultColor: Color {
        switch viewModel.lastExportResult {
        case .success: return .green
        case .failure: return .red
        case nil: return .secondary
        }
    }

    private var resultIcon: String {
        switch viewModel.lastExportResult {
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.circle.fill"
        case nil: return "clock.circle"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: resultIcon)
                .foregroundStyle(resultColor)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.statusMessage)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text("Last: \(lastExportText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if case .failure(let error) = viewModel.lastExportResult {
                    Text(error.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if viewModel.isExporting {
                ProgressView()
            }
        }
    }
}
