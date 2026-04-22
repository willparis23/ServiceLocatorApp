import Foundation

protocol ServiceProviding {
    func fetchServices() async throws -> [Service]
}

enum ServiceError: Error, LocalizedError {
    case networkError
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to connect. Please check your connection and try again."
        case .noResults:
            return "No services found in your area."
        }
    }
}

/// In-memory service provider backed by an HSDS-aligned data model.
/// In production this would be replaced by an `HSDSNetworkProvider` that
/// fetches from a 211 or Open Referral-compliant endpoint. The protocol
/// boundary is what lets us swap implementations without rewriting tests.
final class MockServiceProvider: ServiceProviding {
    var shouldFail: Bool = false
    var shouldReturnEmpty: Bool = false
    var artificialDelay: TimeInterval = 0.5
    
    func fetchServices() async throws -> [Service] {
        try await Task.sleep(nanoseconds: UInt64(artificialDelay * 1_000_000_000))
        
        if shouldFail {
            throw ServiceError.networkError
        }
        
        if shouldReturnEmpty {
            return []
        }
        
        return Self.atlantaMetroServices
    }
    
    // Real Atlanta-metro services with accurate approximate coordinates,
    // spread across Fulton, Cobb, Bartow, and DeKalb counties so results
    // vary meaningfully based on the user's location.
    static let atlantaMetroServices: [Service] = [
        // Cobb / Bartow — near Acworth
        Service(
            name: "MUST Ministries Cobb Service Center",
            category: .food,
            address: "1407 Cobb Pkwy N, Marietta, GA",
            phone: "(770) 427-9862",
            hours: "Mon-Fri 9am-4pm",
            description: "Food pantry, clothing closet, and housing assistance for Cobb County residents.",
            latitude: 33.9849,
            longitude: -84.5144
        ),
        Service(
            name: "Bartow Collaborative",
            category: .housing,
            address: "100 Zena Dr, Cartersville, GA",
            phone: "(770) 387-1908",
            hours: "Mon-Thu 8am-5pm",
            description: "Coordinated housing, food, and family support services for Bartow County families.",
            latitude: 34.1704,
            longitude: -84.8007
        ),
        Service(
            name: "The Center for Family Resources",
            category: .employment,
            address: "995 Roswell St NE, Marietta, GA",
            phone: "(770) 428-2601",
            hours: "Mon-Fri 8am-5pm",
            description: "Employment coaching, financial literacy, and family stabilization services.",
            latitude: 33.9607,
            longitude: -84.5436
        ),
        Service(
            name: "Highland Rivers Behavioral Health",
            category: .mentalHealth,
            address: "1025 S Tennessee St, Cartersville, GA",
            phone: "(770) 387-3113",
            hours: "Mon-Fri 8am-6pm, crisis line 24/7",
            description: "Outpatient mental health services, crisis intervention, and substance use support.",
            latitude: 34.1509,
            longitude: -84.8118
        ),
        
        // North Fulton — Roswell / Alpharetta
        Service(
            name: "North Fulton Community Charities",
            category: .food,
            address: "11270 Elkins Rd, Roswell, GA",
            phone: "(770) 640-0399",
            hours: "Mon-Fri 9am-4pm, Sat 9am-noon",
            description: "Emergency assistance including food pantry, financial help, and thrift store.",
            latitude: 34.0613,
            longitude: -84.3358
        ),
        
        // Downtown / Midtown Atlanta
        Service(
            name: "Atlanta Community Food Bank",
            category: .food,
            address: "3400 N Desert Dr, East Point, GA",
            phone: "(404) 892-9822",
            hours: "Mon-Fri 8am-5pm",
            description: "Partner agency network providing food assistance across metro Atlanta.",
            latitude: 33.6532,
            longitude: -84.4654
        ),
        Service(
            name: "Mercy Care Atlanta",
            category: .healthcare,
            address: "424 Decatur St SE, Atlanta, GA",
            phone: "(678) 843-8500",
            hours: "Mon-Fri 7am-5pm",
            description: "Low-cost medical, dental, and behavioral health care regardless of ability to pay.",
            latitude: 33.7543,
            longitude: -84.3732
        ),
        Service(
            name: "Grady Health System",
            category: .healthcare,
            address: "80 Jesse Hill Jr Dr SE, Atlanta, GA",
            phone: "(404) 616-1000",
            hours: "24 hours",
            description: "Full-service public hospital with urgent care, clinics, and prescription assistance.",
            latitude: 33.7509,
            longitude: -84.3838
        ),
        Service(
            name: "Covenant House Georgia",
            category: .housing,
            address: "1559 Johnson Rd NW, Atlanta, GA",
            phone: "(404) 589-0163",
            hours: "24 hours",
            description: "Shelter, housing, and support services for young people experiencing homelessness.",
            latitude: 33.7949,
            longitude: -84.4232
        ),
        Service(
            name: "WorkSource Atlanta",
            category: .employment,
            address: "818 Pollard Blvd SW, Atlanta, GA",
            phone: "(404) 546-3000",
            hours: "Mon-Fri 8am-5pm",
            description: "Job search assistance, resume support, and free workforce training programs.",
            latitude: 33.7320,
            longitude: -84.4037
        ),
        Service(
            name: "The Gateway Center",
            category: .housing,
            address: "275 Pryor St SW, Atlanta, GA",
            phone: "(404) 215-6600",
            hours: "24 hours",
            description: "Homeless services hub with shelter, case management, and employment support.",
            latitude: 33.7484,
            longitude: -84.3907
        ),
        Service(
            name: "Skyland Trail",
            category: .mentalHealth,
            address: "1961 N Druid Hills Rd NE, Atlanta, GA",
            phone: "(404) 315-8333",
            hours: "Mon-Fri 8am-5pm",
            description: "Nonprofit mental health treatment for adults, including therapy and day programs.",
            latitude: 33.8207,
            longitude: -84.3368
        )
    ]
}
