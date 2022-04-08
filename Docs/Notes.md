# Notes

## UIRefreshControl + viewport-fit=cover bug

To scale the viewport of a browser to fill the display, you may have set viewport-fit=cover;
`<meta name="viewport" content="viewport-fit=cover">`.

If a view `allowsPullToRefresh` in a turbo-ios native app with `viewport-fit=cover`, 
the UIRefreshControl will not be positioned as expected.

You can fix this by conditionally removing `viewport-fit=cover` when loading in a native app.
