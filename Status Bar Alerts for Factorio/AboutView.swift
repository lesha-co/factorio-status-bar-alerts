import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            VStack(alignment: .leading, spacing: 8) {
                Text("Status Bar Alerts for Factorio")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version \(appVersion) (\(buildNumber))")
                    .foregroundStyle(.secondary)

                Text("Monitor your Factorio factory from status bar.")
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    Link(
                        "Visit Website",
                        destination: URL(string: "https://lesha.co/msba")!
                    )
                    Link(
                        "Support the developer",
                        destination: URL(string: "https://lesha.co/support")!
                    )
                }
            }

        }
        .padding()
    }
}

#Preview {
    AboutView()
}
