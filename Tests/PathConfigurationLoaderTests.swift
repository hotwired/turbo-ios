import OHHTTPStubs
import OHHTTPStubsSwift
@testable import Turbo
import XCTest

class PathConfigurationLoaderTests: XCTestCase {
    private let serverURL = URL(string: "http://turbo.test/configuration.json")!
    private let fileURL = Bundle.module.url(forResource: "test-configuration", withExtension: "json", subdirectory: "Fixtures")!

    func test_load_data_automaticallyLoadsFromPassedInDataAndCallsHandler() throws {
        let data = try! Data(contentsOf: fileURL)
        let loader = PathConfigurationLoader(sources: [.data(data)])

        var loadedConfig: PathConfigurationDecoder? = nil
        loader.load { loadedConfig = $0 }

        let config = try XCTUnwrap(loadedConfig)
        XCTAssertEqual(config.rules.count, 5)
    }

    func test_file_automaticallyLoadsFromTheLocalFileAndCallsTheHandler() throws {
        let loader = PathConfigurationLoader(sources: [.file(fileURL)])

        var loadedConfig: PathConfigurationDecoder? = nil
        loader.load { loadedConfig = $0 }

        let config = try XCTUnwrap(loadedConfig)
        XCTAssertEqual(config.rules.count, 5)
    }

    func test_server_automaticallyDownloadsTheFileAndCallsTheHandler() throws {
        let loader = PathConfigurationLoader(sources: [.server(serverURL)])
        let expectation = stubRequest(for: loader)

        var loadedConfig: PathConfigurationDecoder? = nil
        loader.load { config in
            loadedConfig = config
            expectation.fulfill()
        }
        wait(for: [expectation])

        let config = try XCTUnwrap(loadedConfig)
        XCTAssertEqual(config.rules.count, 1)
    }

    func test_server_cachesTheFile() {
        let loader = PathConfigurationLoader(sources: [.server(serverURL)])
        let expectation = stubRequest(for: loader)

        var handlerCalled = false
        loader.load { _ in
            handlerCalled = true
            expectation.fulfill()
        }
        wait(for: [expectation])

        XCTAssertTrue(handlerCalled)
        XCTAssertTrue(FileManager.default.fileExists(atPath: loader.configurationCacheURL.path))
    }

    private func stubRequest(for loader: PathConfigurationLoader) -> XCTestExpectation {
        stub(condition: { _ in true }) { _ in
            let json = ["rules": [["patterns": ["/new"], "properties": ["presentation": "test"]] as [String: Any]]]
            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: [:])
        }

        clearCache(loader.configurationCacheURL)

        return expectation(description: "Wait for configuration to load.")
    }

    private func clearCache(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {}
    }
}
