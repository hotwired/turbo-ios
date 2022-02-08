public typealias LoggingFunction = (String) -> Void

public func configure(logger: LoggingFunction?) {
    Logging.logger = logger
}
