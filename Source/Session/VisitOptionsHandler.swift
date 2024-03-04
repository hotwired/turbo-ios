import Foundation

class VisitOptionsHandler {
    
    private var unhandledVisitOptions: VisitOptions?
    
    /// If a form submission provides a response HTML, save the options and pass them to the next visit proposal.
    func process(_ options: VisitOptions?) -> VisitOptions {
        
        if let options, options.response?.responseHTML != nil {
            /// Options are provided for the next visit.
            unhandledVisitOptions = options
            return options
        } else if let unhandledVisitOptions {
            /// Next visit is happening. Use the previous visit options.
            self.unhandledVisitOptions = nil
            return unhandledVisitOptions
        } else {
            /// No options are unhandled.
            return options ?? VisitOptions()
        }
    }
    
}
