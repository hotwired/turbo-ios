import XCTest
import Quick
import Nimble
import OHHTTPStubs
@testable import Turbo

class PathConfigurationLoaderSpec: QuickSpec {
    override func spec() {
        let serverURL = URL(string: "http://turbo.test/configuration.json")!
        let fileURL = Bundle(for: type(of: self)).url(forResource: "test-configuration", withExtension: "json")!
        
        describe("load") {
            context("data") {
                it("automatically loads from passed in data and calls the handler") {
                    let data = try! Data(contentsOf: fileURL)
                    let loader = PathConfigurationLoader(sources: [.data(data)])
                    
                    var config: PathConfigurationDecoder? = nil
                    loader.load { conf in
                        config = conf
                    }
                    
                    expect(config).toEventuallyNot(beNil())
                    expect(config!.rules.count) == 4
                }
            }
            
            context("file") {
                it("automatically loads from the local file and calls the handler") {
                    let loader = PathConfigurationLoader(sources: [.file(fileURL)])
                    
                    var config: PathConfigurationDecoder? = nil
                    loader.load { conf in
                        config = conf
                    }
                    
                    expect(config).toNot(beNil())
                    expect(config!.rules.count) == 4
                }
            }
            
            context("server") {
                var loader: PathConfigurationLoader!
                
                beforeEach {
                    loader = PathConfigurationLoader(sources: [.server(serverURL)])
                    stub(condition: { _ in true }) { _ in
                        let json = ["rules": [["patterns": ["/new"], "properties": ["presentation": "test"]]]]
                        return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: [:])
                    }
                    
                    clearCache(loader.configurationCacheURL)
                }
                
                it("automatically downloads the file and calls the handler") {
                    var config: PathConfigurationDecoder? = nil
                    loader.load { conf in
                        config = conf
                    }
                    
                    expect(config).toEventuallyNot(beNil())
                    expect(config!.rules.count) == 1
                }
                
                it("caches the file") {
                    var handlerCalled = false
                    loader.load { rs in
                        handlerCalled = true
                    }
                    
                    expect(handlerCalled).toEventually(beTrue())
                    expect(FileManager.default.fileExists(atPath: loader!.configurationCacheURL.path)) == true
                }
            }
            
            context("when file and remote") {
                it("loads the file url and the remote url") {
                    let loader = PathConfigurationLoader(sources: [.file(fileURL), .server(serverURL)])
                    clearCache(loader.configurationCacheURL)
                    
                    stub(condition: { _ in true }) { _ in
                        let json = ["rules": [["patterns": ["/new"], "properties": ["presentation": "test"]]]]
                        return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: [:])
                    }
                    
                    var handlerCalledTimes = 0
                    
                    loader.load { config in
                        if handlerCalledTimes == 0 {
                            expect(config.rules.count) == 4
                        } else {
                            expect(config.rules.count) == 1
                        }
                        
                        handlerCalledTimes += 1
                    }
                    
                    expect(handlerCalledTimes).toEventually(equal(2))
                }
            }
        }
    }
}

private func clearCache(_ url: URL) {
    do {
        try FileManager.default.removeItem(at: url)
    } catch {}
}
