import Foundation

struct Demo {
    static let basic = URL(string: "https://turbo-native-demo.glitch.me")!
    static let local = URL(string: "http://localhost:45678")!
    
    /// Update this to choose which demo is run
    static var current: URL {
        local
    }
}
