import Foundation

typealias PathConfigurationLoaderCompletionHandler = (PathConfigurationDecoder) -> Void

final class PathConfigurationLoader {
    private let cacheDirectory = "Turbo"
    private let sources: [PathConfiguration.Source]
    private let options: PathConfigurationLoaderOptions?
    private var completionHandler: PathConfigurationLoaderCompletionHandler?
    
    init(sources: [PathConfiguration.Source], options: PathConfigurationLoaderOptions? = nil) {
        self.sources = sources
        self.options = options
    }
    
    func load(then completion: @escaping PathConfigurationLoaderCompletionHandler) {
        completionHandler = completion
        
        for source in sources {
            switch source {
            case .data(let data):
                loadData(data, for: .PathDataTemporaryURL)
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
        if let data = cachedData(for: url) {
            loadData(data, for: url)
        }
        
        let session = options?.urlSessionConfiguration.map { URLSession(configuration: $0) } ?? URLSession.shared
        
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                debugPrint("[path-configuration] *** error - invalid response or data: \(String(describing: response)), error: \(String(describing: error))")
                return
            }
            
            self?.loadData(data, cache: true, for: url)
        }.resume()
    }
    
    // MARK: - Caching
    
    private func cacheRemoteData(_ data: Data, for url: URL) {
        createCacheDirectoryIfNeeded()
        
        do {
            let url = configurationCacheURL(for: url)
            try data.write(to: url)
        } catch {
            debugPrint("[path-configuration-loader] error caching file error: \(error)")
        }
    }
    
    private func cachedData(for url: URL) -> Data? {
        let cachedURL = configurationCacheURL(for: url)
        guard FileManager.default.fileExists(atPath: cachedURL.path) else {
            return nil
        }
        
        do {
            return try Data(contentsOf: cachedURL)
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
    
    func configurationCacheURL(for url: URL) -> URL {
        turboCacheDirectoryURL.appendingPathComponent(url.lastPathComponent)
    }
    
    // MARK: - File
    
    private func loadFile(_ url: URL) {
        precondition(url.isFileURL, "URL provided for file is not a file url")
        
        do {
            let data = try Data(contentsOf: url)
            loadData(data, for: url)
        } catch {
            debugPrint("[path-configuration] *** error loading configuration from file: \(url), error: \(error)")
        }
    }
    
    // MARK: - Data
    
    private func loadData(_ data: Data, cache: Bool = false, for url: URL) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw JSONDecodingError.invalidJSON
            }
            
            let config = try PathConfigurationDecoder(json: json)
            
            if cache {
                // Only cache once we ensure we have valid data
                cacheRemoteData(data, for: url)
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

private extension URL {
    static let PathDataTemporaryURL = URL(string: "https://localhost/path-configuration.json")!
}
