import Foundation
import CoreLocation

struct Service: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let category: ServiceCategory
    let address: String
    let phone: String
    let hours: String
    let description: String
    let latitude: Double
    let longitude: Double
    
    init(
        id: UUID = UUID(),
        name: String,
        category: ServiceCategory,
        address: String,
        phone: String,
        hours: String,
        description: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.address = address
        self.phone = phone
        self.hours = hours
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var coordinate: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func distanceInMiles(from userLocation: CLLocation) -> Double {
        coordinate.distance(from: userLocation) / 1609.34
    }
}

enum ServiceCategory: String, Codable, CaseIterable, Identifiable {
    case food = "Food Assistance"
    case housing = "Housing Support"
    case mentalHealth = "Mental Health"
    case healthcare = "Healthcare"
    case employment = "Employment"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .housing: return "house.fill"
        case .mentalHealth: return "heart.circle.fill"
        case .healthcare: return "cross.case.fill"
        case .employment: return "briefcase.fill"
        }
    }
    
    var accessibilityDescription: String {
        "Category: \(rawValue)"
    }
}
