(() => {
  // Bridge between Turbo JS and native code. Built for Turbo 7
  // with backwards compatibility for Turbolinks 5
  class TurboNative {
    constructor(messageHandler) {
      this.messageHandler = webkit.messageHandlers.turbo
      this.registerAdapter()
     }

    registerAdapter() {
      if (window.Turbo) {
        if (Turbo.controller) {
          Turbo.controller.adapter = this
        } else {
          window.Turbo.registerAdapter(this)
        }
      } else if (window.Turbolinks) {
        Turbolinks.controller.adapter = this
      } else {
        this.pageLoadFailed()
      }
    }

    pageLoaded() {
      let restorationIdentifier = ""

      if (window.Turbo) {
        if (Turbo.navigator) {
          restorationIdentifier = Turbo.navigator.currentVisit.restorationIdentifier
        } else {
          restorationIdentifier = Turbo.controller.restorationIdentifier
        }
      } else if (window.Turbolinks) {
        restorationIdentifier = Turbolinks.controller.restorationIdentifier
      }

       this.postMessageAfterNextRepaint("pageLoaded", { restorationIdentifier: restorationIdentifier })
    }

    pageLoadFailed() {
      this.postMessage("pageLoadFailed")
    }

    errorRaised(error) {
      this.postMessage("errorRaised", { error: error })
    }

    visitLocationWithOptionsAndRestorationIdentifier(location, options, restorationIdentifier) {
      if (window.Turbo) {
        if (Turbo.controller) {
          Turbo.controller.startVisitToLocation(location, restorationIdentifier, options)
        } else if (Turbo.navigator) {
          Turbo.navigator.startVisit(location, restorationIdentifier, options)
        }
      } else if (window.Turbolinks) {
        if (Turbolinks.controller.startVisit) {
          // Turbolinks 5.3
          Turbolinks.controller.startVisit(location, restorationIdentifier, options)
        } else {
          // Turbolinks 5
          Turbolinks.controller.startVisitToLocationWithAction(location, options.action, restorationIdentifier)
        }
      }
    }

    // Current visit

    issueRequestForVisitWithIdentifier(identifier) {
      if (identifier == this.currentVisit.identifier) {
        this.currentVisit.issueRequest()
      }
    }

    changeHistoryForVisitWithIdentifier(identifier) {
      if (identifier == this.currentVisit.identifier) {
        this.currentVisit.changeHistory()
      }
    }

    loadCachedSnapshotForVisitWithIdentifier(identifier) {
      if (identifier == this.currentVisit.identifier) {
        this.currentVisit.loadCachedSnapshot()
      }
    }

    loadResponseForVisitWithIdentifier(identifier) {
      if (identifier == this.currentVisit.identifier) {
        this.currentVisit.loadResponse()
      }
    }

    cancelVisitWithIdentifier(identifier) {
      if (identifier == this.currentVisit.identifier) {
        this.currentVisit.cancel()
      }
    }

    // Adapter interface

    visitProposedToLocation(location, options) {
      this.postMessage("visitProposed", { location: location.absoluteURL, options: options })
    }

    // Turbolinks 5 compatibility
    visitProposedToLocationWithAction(location, action) {
      this.visitProposedToLocation(location, { action })
    }

    visitStarted(visit) {
      this.currentVisit = visit
      this.postMessage("visitStarted", { identifier: visit.identifier, hasCachedSnapshot: visit.hasCachedSnapshot() })
      this.issueRequestForVisitWithIdentifier(visit.identifier)
      this.changeHistoryForVisitWithIdentifier(visit.identifier)
      this.loadCachedSnapshotForVisitWithIdentifier(visit.identifier)
    }

    visitRequestStarted(visit) {
      this.postMessage("visitRequestStarted", { identifier: visit.identifier })
    }

    visitRequestCompleted(visit) {
      this.postMessage("visitRequestCompleted", { identifier: visit.identifier })
      this.loadResponseForVisitWithIdentifier(visit.identifier)
    }

    visitRequestFailedWithStatusCode(visit, statusCode) {
      this.postMessage("visitRequestFailed", { identifier: visit.identifier, statusCode: statusCode })
    }

    visitRequestFinished(visit) {
      this.postMessage("visitRequestFinished", { identifier: visit.identifier })
    }

    visitRendered(visit) {
      this.postMessageAfterNextRepaint("visitRendered", { identifier: visit.identifier })
    }

    visitCompleted(visit) {
      this.postMessage("visitCompleted", { identifier: visit.identifier, restorationIdentifier: visit.restorationIdentifier })
    }

    pageInvalidated() {
      this.postMessage("pageInvalidated")
    }

    log(message) {
      this.postMessage("log", { message: message })
    }
      
    // Private

    postMessage(name, data = {}) {
      data["timestamp"] = Date.now()
      this.messageHandler.postMessage({ name: name, data: data })
    }

    postMessageAfterNextRepaint(name, data) {
      // Post immediately if document is hidden or message may be queued by call to rAF
      if (document.hidden) {
        this.postMessage(name, data);
      } else {
        var postMessage = this.postMessage.bind(this, name, data)
        requestAnimationFrame(() => {
          requestAnimationFrame(postMessage)
        })
      }
    }
  }

  addEventListener("error", event => {
    const error = event.message + " (" + event.filename + ":" + event.lineno + ":" + event.colno + ")"
    window.turboNative.errorRaised(error)
  }, false)

  window.turboNative = new TurboNative()
  window.turboNative.pageLoaded()
})()
