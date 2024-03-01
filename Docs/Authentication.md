# Authentication
There are a number of ways to handle authentication in a Turbo Native iOS app. Primarily, you will be authenticating the user through a web view and relying on cookies. The framework however doesn't provide any auth-specific handling or APIs, that's completely up to each app, depending on their configuration.

## Cookies
If your app does not need to make any authenticated network requests from native code, you can simply use cookies like in a web browser. When your user authenticates, set the appropriate cookies and make sure they are persistent, not session cookies. `WKWebView` will automatically handle persisting those cookies to disk as appropriate between app launches. All your web and XHR requests will then just work.

## Native & Web
If you need to make authenticated network requests from both the web and native code, it's a little more complex, and depends on your particular app. You can authenticate natively and somehow hand those credentials to the web view, or authenticate in the web and send those credentials to native. We don't have any particular recommendations there, but can tell you how we decided to handle it in our apps.

### Basecamp 3 and HEY
For Basecamp 3 and HEY, we perform authentication completely natively, and get an OAuth token back from our API. We then securely persist this token in the user's Keychain. This OAuth token is used for all network requests by setting a header in `URLSession`. This OAuth token is used for all native screens and extensions (share, widgets, today, watch, etc).

For Basecamp 3, when you load a web view for the first time in our app, we get a 401 from the server. We handle that response by making a special request in a hidden `WKWebView` to an endpoint on our server using our OAuth token which sets the appropriate cookies for the web view. When that request finishes successfully, we know the cookies are set and Turbo is ready to go. This only happens the first launch, as the web view cookies will be persisted as mentioned above. The key to this strategy is to create a `URLRequest` using the OAuth header, and use that to load the web view calling `webView.load(request)` for the authentication request. If the web view is different from the Turbo web view, you'll need to also ensure they're using the same `WKProcessPool` so the cookies are shared.

For HEY, we have a slightly different approach. We get the cookies back along with our initial OAuth request and set those cookies directly to the web view and global cookie stores.
