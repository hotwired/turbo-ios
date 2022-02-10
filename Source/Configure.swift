public typealias LoggingFunction = (@autoclosure () -> String) -> Void

public func configure(logger: LoggingFunction?) {
    Logging.logger = logger
}
