import Foundation

typealias PathConfigurationLoaderCompletionHandler = (PathConfigurationDecoder) -> Void

final class PathConfigurationLoader {
    private let cacheDirectory = "Turbo"
    private let configurationCacheFilename = "path-configuration.json"
    private let sources: [PathConfiguration.Source]
    private var completionHandler: PathConfigurationLoaderCompletionHandler?
    
    init(sources: [PathConfiguration.Source]) {
        self.sources = sources
    }
    
    func load(then completion: @escaping PathConfigurationLoaderCompletionHandler) {
        completionHandler = completion
        
        for source in sources {
            switch source {
            case .data(let data):
                loadData(data)
            case .file(let url):
                loadFile(url)
            case .server(let url):
                download(from: url)
            }
        }
    }
    
    // MARK: - Server
    
    private func download(from url: URL) {
        precondition(!url.isFileURL, "URL provided for server is a file url")
        
        // Immediately load most recent cached version if available
        if let data = cachedData() {
            loadData(data)
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                debugPrint("[path-configuration] *** error - invalid response or data: \(String(describing: response)), error: \(String(describing: error))")
                return
            }
            
            self?.loadData(data, cache: true)
        }.resume()
    }
    
    // MARK: - Caching
    
    private func cacheRemoteData(_ data: Data) {
        createCacheDirectoryIfNeeded()
        
        do {
            try data.write(to: configurationCacheURL)
        } catch {
            debugPrint("[path-configuration-loader] error caching file error: \(error)")
        }
    }
    
    private func cachedData() -> Data? {
        guard FileManager.default.fileExists(atPath: configurationCacheURL.path) else {
            return nil
        }
        
        do {
            return try Data(contentsOf: configurationCacheURL)
        } catch {
            debugPrint("[path-configuration-loader] *** error loading cached data: \(error)")
            return nil
        }
    }
    
    private func createCacheDirectoryIfNeeded() {
        guard !FileManager.default.fileExists(atPath: turboCacheDirectoryURL.path) else { return }
        
        do {
            try FileManager.default.createDirectory(at: turboCacheDirectoryURL, withIntermediateDirectories: false, attributes: nil)
        } catch {
            debugPrint("[path-configuration-loader] *** error creating cache directory: \(error)")
        }
    }
    
    private var turboCacheDirectoryURL: URL {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(cacheDirectory)
    }
    
    var configurationCacheURL: URL {
        turboCacheDirectoryURL.appendingPathComponent(configurationCacheFilename)
    }
    
    // MARK: - File
    
    private func loadFile(_ url: URL) {
        precondition(url.isFileURL, "URL provided for file is not a file url")
        
        do {
            let data = try Data(contentsOf: url)
            loadData(data)
        } catch {
            debugPrint("[path-configuration] *** error loading configuration from file: \(url), error: \(error)")
        }
    }
    
    // MARK: - Data
    
    private func loadData(_ data: Data, cache: Bool = false) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw JSONDecodingError.invalidJSON
            }
            
            let config = try PathConfigurationDecoder(json: json)
            
            if cache {
                // Only cache once we ensure we have valid data
                cacheRemoteData(data)
            }
            
            updateHandler(with: config)
        } catch {
            debugPrint("[path-configuration] *** error decoding path configuration: \(error)")
        }
    }
    
    // MARK: - Delegate
    
    private func updateHandler(with config: PathConfigurationDecoder) {
        if Thread.isMainThread {
            completionHandler?(config)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.completionHandler?(config)
            }
        }
    }
}
