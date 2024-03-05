# Path Configuration

The "path configuration" is a feature that simplifies mapping various urls to "path properties". When possible, it's preferred to get data for a page from the page itself through the DOM or a library like Strada (see [advanced](Advanced.md)). However, certain properties you need to know *before* the page loads. This can be anything you want from the title, the background color, the presentation, or which view controller to load. Using a path configuration is completely optional and not required to use Turbo iOS.

The path configuration itself is a JSON file with the following structure:

```json
{
  "settings": {
    "enable-feature-x": true
  },
  "rules": [
    {
      "patterns": [
        "/new$",
        "/edit$"
      ],
      "properties": {
        "presentation": "modal"
      }
    },
    {
      "patterns": [
        "/sign_in",
      ],
      "properties": {
        "appearance": "dark"
      }
    },
  ]
}
```


You tell the `Session` about the path configuration creating a `PathConfiguration` and setting it on the `Session`:

```swift
let pathConfiguration = PathConfiguration(sources: [
  .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!)
])

session.pathConfiguration = pathConfiguration
```

The `PathConfiguration` object can be set on multiple sessions at once and used from your own code.

## Sources

A path configuration has an array of `sources`. You can configure the source to be a locally bundled file, a remote file available from your server, or both. We recommend always including a bundled version even when loading remotely, so it will be available in case your app is offline.

Providing a bundled file and a server location will cause the path configuration to immediately load from the bundled version and then download the server version. When downloading from a server, it will also cache that latest version locally, and attempt to load it before making the network request. That way you have a chain of configurations available, always using the latest version when available, but falling back to cache or bundle as needed.

```swift
let pathConfiguration = PathConfiguration(sources: [
  .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!),
  .server(URL(string: "https://example.com/your-path-config.json")!)
])
```

## Path Properties

Path properties are the core of the path configuration. The `rules` key of the JSON is an array of dictionaries. Each dictionary has a `patterns` array which is an array of regular expressions for matching on the URL, and a dictionary of `properties` that will get returned when a pattern matches.

You can lookup the properties for a URL by using the URL itself or the `url.path` value. The path configuration finds all matching rules in order, and then merges them into one dictionary, with later rules overriding earlier ones. This way you can group similar properties together.

Given the following rules:

```json
[
    {
      "patterns": [
        "/new$",
        "/edit$"
      ],
      "properties": {
        "presentation": "modal"
      }
    },
    {
      "patterns": [
        "/messages/new$",
      ],
      "properties": {
        "appearance": "dark"
      }
    },
  ]
```

The url `example.com/new` will only match the first rule and return: 

```json
{ 
  "presentation": "modal" 
}
```

The url `example.com/messages/new` however would match both the first and second rule, and return the combined properties of:

```json
{ 
  "presentation": "modal", 
  "appearance": "dark" 
}
```

When the `Session` proposes a visit, it looks up the path properties for the proposed visit url if it has a `pathConfiguration` and it passes those path properties to your app in the `VisitProposal` via `proposal.properties`. This is for convenience, but you can also use the path configuration directly and do the same lookup in your application code.

### Matching the Query

By default, the path configuration only looks at the path component of the URL. You can also include the query when matching with the following:

```swift
pathConfiguration.properties(for: url, considerParams: true)
```

To ensure the order of query items don't effect matching, a wildcard `.*` before and after the match is recommended, like so:

```
{
  "patterns": [".*\\?.*foo=bar.*"],
  "properties": {
    "foo": "bar"
  }
}
```

## Settings

The path configuration optionally can have a top-level `settings` dictionary. This can be whatever data you want. We use it for controlling anything that we want the flexibility to change from the server without releasing an update. This might be different urls, configurations, feature flags, etc. If you don't want to use that, you can omit it entirely from the JSON.

It can be accessed like this:

```swift
if let enableFeatureX = pathConfiguration.settings["enable-feature-x"] as? Bool {
  // Do something with `enableFeatureX` boolean value
}
```

