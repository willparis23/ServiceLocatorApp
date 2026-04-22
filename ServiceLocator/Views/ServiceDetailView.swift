import SwiftUI

struct ServiceDetailView: View {
    let service: Service
    let distanceText: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                Divider()
                infoSection(
                    icon: "location.fill",
                    title: "Address",
                    content: service.address,
                    identifier: "addressSection"
                )
                infoSection(
                    icon: "phone.fill",
                    title: "Phone",
                    content: service.phone,
                    identifier: "phoneSection"
                )
                infoSection(
                    icon: "clock.fill",
                    title: "Hours",
                    content: service.hours,
                    identifier: "hoursSection"
                )
                descriptionSection
                Spacer(minLength: 20)
                actionButtons
            }
            .padding()
        }
        .navigationTitle(service.name)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("serviceDetailScreen")
    }
    
    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: service.category.iconName)
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
                .frame(width: 64, height: 64)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityIdentifier("serviceNameLabel")
                Text(service.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("serviceCategoryLabel")
                Text(distanceText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("serviceDistanceLabel")
            }
            Spacer()
        }
    }
    
    private func infoSection(
        icon: String,
        title: String,
        content: String,
        identifier: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(content)
                    .font(.body)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(content)")
        .accessibilityIdentifier(identifier)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this service")
                .font(.headline)
            Text(service.description)
                .font(.body)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("descriptionSection")
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                // In a real app this would trigger a phone call
            } label: {
                Label("Call", systemImage: "phone.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("callButton")
            .accessibilityHint("Calls \(service.phone)")
            
            Button {
                // In a real app this would open Maps
            } label: {
                Label("Directions", systemImage: "map.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("directionsButton")
            .accessibilityHint("Opens directions in Maps")
        }
    }
}

#Preview {
    NavigationStack {
        ServiceDetailView(
            service: MockServiceProvider.atlantaMetroServices[0],
            distanceText: "2.3 miles away"
        )
    }
}
