(() => {
  const TURBO_LOAD_TIMEOUT = 4000

  // Bridge between Turbo JS and native code. Built for Turbo 7
  // with backwards compatibility for Turbolinks 5
  class TurboNative {
    constructor() {
      this.messageHandler = webkit.messageHandlers.turbo
     }

    registerAdapter() {
      if (window.Turbo) {
        Turbo.registerAdapter(this)
      } else if (window.Turbolinks) {
        Turbolinks.controller.adapter = this
      }
    }

    pageLoaded() {
      let restorationIdentifier = ""

      if (window.Turbo) {
        restorationIdentifier = Turbo.navigator.restorationIdentifier
      } else if (window.Turbolinks) {
        restorationIdentifier = Turbolinks.controller.restorationIdentifier
      }

       this.postMessageAfterNextRepaint("pageLoaded", { restorationIdentifier })
    }

    pageLoadFailed() {
      this.postMessage("pageLoadFailed")
    }

    errorRaised(error) {
      this.postMessage("errorRaised", { error: error })
    }

    visitLocationWithOptionsAndRestorationIdentifier(location, options, restorationIdentifier) {
      if (window.Turbo) {
        Turbo.navigator.startVisit(location, restorationIdentifier, options)
      } else if (window.Turbolinks) {
        if (Turbolinks.controller.startVisitToLocationWithAction) {
          // Turbolinks 5
          Turbolinks.controller.startVisitToLocationWithAction(location, options.action, restorationIdentifier)
        } else {
          // Turbolinks 5.3
          Turbolinks.controller.startVisitToLocation(location, restorationIdentifier, options)
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
      if (window.Turbo && typeof Turbo.navigator.locationWithActionIsSamePage === "function") {
        if (Turbo.navigator.locationWithActionIsSamePage(location, options.action)) {
          Turbo.navigator.view.scrollToAnchorFromLocation(location)
          return
        }
      }

      this.postMessage("visitProposed", { location: location.toString(), options: options })
    }

    // Turbolinks 5
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

  const setup = function() {
    window.turboNative.registerAdapter()
    window.turboNative.pageLoaded()

    document.removeEventListener("turbo:load")
    document.removeEventListener("turbolinks:load")
  }

  const setupOnLoad = () => {
    document.addEventListener("turbo:load", setup)
    document.addEventListener("turbolinks:load", setup)

    setTimeout(() => {
      if (!window.Turbo && !window.Turbolinks) {
        window.turboNative.pageLoadFailed()
      }
    }, TURBO_LOAD_TIMEOUT)
  }

  if (window.Turbo || window.Turbolinks) {
    setup()
  } else {
    setupOnLoad()
  }
})()
