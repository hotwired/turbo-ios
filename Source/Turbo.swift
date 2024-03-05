public enum Turbo {
    public static var config = TurboConfig()
}

public class TurboConfig {
    public var debugLoggingEnabled = false {
        didSet {
            TurboLog.debugLoggingEnabled = debugLoggingEnabled
        }
    }

    public var matchPathConfigurationQuery = false
}
