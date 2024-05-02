(() => {
  const TURBO_LOAD_TIMEOUT = 30000

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
      } else {
        throw new Error("Failed to register the TurboNative adapter")
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
        if (Turbo.navigator.locationWithActionIsSamePage(new URL(location), options.action)) {
          // Skip the same-page anchor scrolling behavior for visits initiated from the native
          // side. The page content may be stale and we want a fresh request from the network.
          Turbo.navigator.startVisit(location, restorationIdentifier, { "action": "replace" })
        } else {
          Turbo.navigator.startVisit(location, restorationIdentifier, options)
        }
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
      
    clearSnapshotCache() {
      if (window.Turbo) {
        Turbo.session.clearCache()
      }
    }

    cacheSnapshot() {
      if (window.Turbo) {
        Turbo.session.view.cacheSnapshot()
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
      if (window.Turbo && Turbo.navigator.locationWithActionIsSamePage(location, options.action)) {
        // Scroll to the anchor on the page
        this.postMessage("visitProposalScrollingToAnchor", { location: location.toString(), options: options })
        Turbo.navigator.view.scrollToAnchorFromLocation(location)
      } else if (window.Turbo && Turbo.navigator.location?.href === location.href) {
        // Refresh the page without native proposal
        this.postMessage("visitProposalRefreshingPage", { location: location.toString(), options: options })
        this.visitLocationWithOptionsAndRestorationIdentifier(location, options, Turbo.navigator.restorationIdentifier)
      } else {
        // Propose the visit
        this.postMessage("visitProposed", { location: location.toString(), options: options })
      }
    }

    // Turbolinks 5
    visitProposedToLocationWithAction(location, action) {
      this.visitProposedToLocation(location, { action })
    }

    visitStarted(visit) {
      this.currentVisit = visit
      this.postMessage("visitStarted", { identifier: visit.identifier, hasCachedSnapshot: visit.hasCachedSnapshot(), isPageRefresh: visit.isPageRefresh || false })
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

    async visitRequestFailedWithStatusCode(visit, statusCode) {
      // Turbo does not permit cross-origin fetch redirect attempts and
      // they'll lead to a visit request failure. Attempt to see if the
      // visit request failure was due to a cross-origin redirect.
      const redirect = await this.fetchFailedRequestCrossOriginRedirect(visit, statusCode)
      const location = visit.location.toString()

      if (redirect != null) {
        this.postMessage("visitProposedToCrossOriginRedirect", { location: redirect.toString(), identifier: visit.identifier })
      } else {
        this.postMessage("visitRequestFailed", { location: location, identifier: visit.identifier, statusCode: statusCode })
      }
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
      
    formSubmissionStarted(formSubmission) {
      this.postMessage("formSubmissionStarted", { location: formSubmission.location.toString() })
    }

    formSubmissionFinished(formSubmission) {
      this.postMessage("formSubmissionFinished", { location: formSubmission.location.toString() })
    }

    pageInvalidated() {
      this.postMessage("pageInvalidated")
    }

    log(message) {
      this.postMessage("log", { message: message })
    }

    // Private
      
    async fetchFailedRequestCrossOriginRedirect(visit, statusCode) {
      // Non-HTTP status codes are sent by Turbo for network
      // failures, including cross-origin fetch redirect attempts.
      if (statusCode <= 0) {
        try {
          const response = await fetch(visit.location, { redirect: "follow" })
          if (response.url != null && response.url.origin != visit.location.origin) {
            return response.url
          }
        } catch {}
      }

      return null
    }

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

    document.removeEventListener("turbo:load", setup)
    document.removeEventListener("turbolinks:load", setup)
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
