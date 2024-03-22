# Turbo Navigator

Turbo Navigator abstracts routing boilerplate a single class. Use this level of abstraction for default handling of the following navigation flows.

## Handled navigation flows

When a link is tapped, turbo-ios sends a `VisitProposal` to your application code. Based on the [Path Configuration](PathConfiguration.md), different `PathProperties` will be set.

* **Current context** - What state the app is in.
    * `modal` - a modal is currently presented
    * `default` - otherwise
* **Given context** - Value of `context` on the requested link.
    * `modal` or `default`/blank
* **Given presentation** - Value of `presentation` on the proposal.
    * `replace`, `pop`, `refresh`, `clear_all`, `replace_root`, `none`, `default`/blank
* **Navigation** - The behavior that the navigation controller provides.

<table>
  <thead>
    <tr>
      <th>Current Context</th>
      <th>Given Context</th>
      <th>Given Presentation</th>
      <th>New Presentation</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>default</code></td>
      <td><code>default</code></td>
      <td><code>default</code></td>
      <td>Push on main stack (or)<br>
        Replace if visiting same page (or)<br>
        Pop (and visit) if previous controller is same URL
      </td>
    </tr>
    <tr>
      <td><code>default</code></td>
      <td><code>default</code></td>
      <td><code>replace</code></td>
      <td>Replace controller on main stack</td>
    </tr>
    <tr>
      <td><code>default</code></td>
      <td><code>modal</code></td>
      <td><code>default</code></td>
      <td>Present a modal with only this controller</td>
    </tr>
    <tr>
      <td><code>default</code></td>
      <td><code>modal</code></td>
      <td><code>replace</code></td>
      <td>Present a modal with only this controller</td>
    </tr>
    <tr>
      <td><code>modal</code></td>
      <td><code>default</code></td>
      <td><code>default</code></td>
      <td>Dismiss then Push on main stack</td>
    </tr>
    <tr>
      <td><code>modal</code></td>
      <td><code>default</code></td>
      <td><code>replace</code></td>
      <td>Dismiss then Replace on main stack</td>
    </tr>
    <tr>
      <td><code>modal</code></td>
      <td><code>modal</code></td>
      <td><code>default</code></td>
      <td>Push on the modal stack</td>
    </tr>
    <tr>
      <td><code>modal</code> </td>
      <td><code>modal</code></td>
      <td><code>replace</code></td>
      <td>Replace controller on modal stack</td>
    </tr>
    <tr>
      <td><code>default</code></td>
      <td>(any)</td>
      <td><code>pop</code></td>
      <td>Pop controller off main stack</td>
    </tr>
    <tr>
      <td><code>default</code></td>
      <td>(any)</td>
      <td><code>refresh</code></td>
      <td>Pop on main stack then</td>
    </tr>
    <tr>
      <td><code>modal</code></td>
      <td>(any)</td>
      <td><code>pop</code></td>
      <td>Pop controller off modal stack (or)<br>
        Dismiss if one modal controller
      </td>
    </tr>
    <tr>
      <td><code>modal</code></td>
      <td>(any)</td>
      <td><code>refresh</code></td>
      <td>Pop controller off modal stack then<br>
        Refresh last controller on modal stack<br>
        (or)<br>
        Dismiss if one modal controller then<br>
        Refresh last controller on main stack
      </td>
    </tr>
    <tr>
      <td>(any)</td>
      <td>(any)</td>
      <td><code>clearAll</code></td>
      <td>Dismiss if modal controller then<br>
        Pop to root then<br>
        Refresh root controller on main stack
      </td>
    </tr>
    <tr>
      <td>(any)</td>
      <td>(any)</td>
      <td><code>replaceRoot</code></td>
      <td>Dismiss if modal controller then<br>
        Pop to root then<br>
        Replace root controller on main stack
      </td>
    </tr>
    <tr>
      <td>(any)</td>
      <td>(any)</td>
      <td><code>none</code></td>
      <td>Nothing</td>
    </tr>
  </tbody>
</table>

### Examples

To present forms (URLs ending in `/new` or `/edit`) as a modal, add the following to the `rules` key of your Path Configuration.

```json
{
  "patterns": [
    "/new$",
    "/edit$"
  ],
  "properties": {
    "context": "modal"
  }
}
```

To hook into the "refresh" turbo-rails native route, add the following to the `rules` key of your Path Configuration. You can then call `refresh_or_redirect_to` in your controller to handle Turbo Native and web-based navigation.

```json
{
  "patterns": [
    "/refresh_historical_location"
  ],
  "properties": {
    "presentation": "refresh"
  }
}
```
