public enum Turbo {
    public static var config = TurboConfig()
}

public class TurboConfig {
    public var debugLoggingEnabled = false {
        didSet {
            TurboLog.debugLoggingEnabled = debugLoggingEnabled
        }
    }

    public var pathConfiguration = PathConfiguration()
}

public extension TurboConfig {
    class PathConfiguration {
        public var matchQueryStrings = false
    }
}
