import Foundation

struct Demo {
    static let basic = URL(string: "https://turbo-native-demo.glitch.me")!
    static let turbolinks5 = URL(string: "https://turbo-native-demo.glitch.me?turbolinks=1")!
    
    static let local = URL(string: "http://localhost:45678")!
    static let turbolinks5Local = URL(string: "http://localhost:45678?turbolinks=1")!

    /// Update this to choose which demo is run
    static var current: URL {
        local
    }
}
