@testable import Turbo
import XCTest

class PathConfigurationTests: XCTestCase {
    private let fileURL = Bundle.module.url(forResource: "test-configuration", withExtension: "json", subdirectory: "Fixtures")!
    var configuration: PathConfiguration!

    override func setUp() {
        configuration = PathConfiguration(sources: [.file(fileURL)])
        XCTAssertGreaterThan(configuration.rules.count, 0)
    }

    func test_init_automaticallyLoadsTheConfigurationFromTheSpecifiedLocation() {
        XCTAssertEqual(configuration.settings.count, 2)
        XCTAssertEqual(configuration.rules.count, 5)
    }

    func test_settings_returnsCurrentSettings() {
        XCTAssertEqual(configuration.settings, [
            "some-feature-enabled": true,
            "server": "beta"
        ])
    }

    func test_propertiesForPath_whenPathMatches_returnsProperties() {
        XCTAssertEqual(configuration.properties(for: "/"), [
            "page": "root"
        ])
    }

    func test_propertiesForPath_whenPathMatchesMultipleRules_mergesProperties() {
        XCTAssertEqual(configuration.properties(for: "/new"), [
            "context": "modal",
            "background_color": "black"
        ])

        XCTAssertEqual(configuration.properties(for: "/edit"), [
            "context": "modal",
            "background_color": "white"
        ])
    }
    
    func test_propertiesForURL_withParams() {
        let url = URL(string: "http://turbo.test/sample.pdf?open_in_external_browser=true")!

        XCTAssertEqual(configuration.properties(for: url), [:])

        XCTAssertEqual(configuration.properties(for: url, considerParams: true), [
            "open_in_external_browser": true
        ])
    }

    func test_propertiesForPath_whenNoMatch_returnsEmptyProperties() {
        XCTAssertEqual(configuration.properties(for: "/missing"), [:])
    }

    func test_subscript_isAConvenienceMethodForPropertiesForPath() {
        XCTAssertEqual(configuration.properties(for: "/new"), configuration["/new"])
        XCTAssertEqual(configuration.properties(for: "/edit"), configuration["/edit"])
        XCTAssertEqual(configuration.properties(for: "/"), configuration["/"])
        XCTAssertEqual(configuration.properties(for: "/missing"), configuration["/missing"])
        XCTAssertEqual(configuration.properties(for: "/sample.pdf?open_in_external_browser=true"), configuration["/sample.pdf?open_in_external_browser=true"])
    }
}

class PathConfigTests: XCTestCase {
    func test_json_withValidJSON_decodesSuccessfully() throws {
        let fileURL = Bundle.module.url(forResource: "test-configuration", withExtension: "json", subdirectory: "Fixtures")!

        let data = try Data(contentsOf: fileURL)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let config = try PathConfigurationDecoder(json: json)

        XCTAssertEqual(config.settings.count, 2)
        XCTAssertEqual(config.rules.count, 5)
    }

    func test_json_withMissingRulesKey_failsToDecode() throws {
        XCTAssertThrowsError(try PathConfigurationDecoder(json: [:])) { error in
            XCTAssertEqual(error as? JSONDecodingError, JSONDecodingError.invalidJSON)
        }
    }
}
