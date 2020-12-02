(() => {
  // NativeBridge sends messages between native app and Turbo JS
  class NativeBridge {
    constructor(controller, messageHandler) {
      this.controller = controller
      this.messageHandler = messageHandler
      controller.adapter = this
    }

    pageLoaded() {
      const restorationIdentifier = this.controller.restorationIdentifier
      this.postMessageAfterNextRepaint("pageLoaded", { restorationIdentifier: restorationIdentifier })
    }

    errorRaised(error) {
      this.postMessage("errorRaised", { error: error })
    }

    visitLocationWithOptionsAndRestorationIdentifier(location, options, restorationIdentifier) {
      if (this.controller.startVisitToLocation) {
        this.controller.startVisitToLocation(location, restorationIdentifier, options)
      } else {
        // Temporarily support old API
        this.controller.startVisitToLocationWithAction(location, options.action)
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

    // Temporary adapter for new API
    visitProposedToLocationWithAction(location, action) {
      this.visitProposedToLocation(location, { action })
    }

    visitProposedToLocation(location, options) {
      this.postMessage("visitProposed", { location: location.absoluteURL, options: options })
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

  window.turboNative = new NativeBridge(Turbolinks.controller, webkit.messageHandlers.turbo)

  addEventListener("error", event => {
    const error = event.message + " (" + event.filename + ":" + event.lineno + ":" + event.colno + ")"
    window.turboNative.errorRaised(error)
  }, false)

  window.turboNative.pageLoaded()
})()
