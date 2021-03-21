###**
Scrolling viewports
===================

The `up.viewport` module controls the scroll position of scrollable containers ("viewports").

The default viewport for any web application is the main document. An application may
define additional viewports by giving the CSS property `{ overflow-y: scroll }` to any `<div>`.


\#\#\# Revealing new content

When following a [link to a fragment](/a-up-target) Unpoly will automatically
scroll the document's viewport to [reveal](/up.viewport) the updated content.

You should [make Unpoly aware](/up.viewport.config#config.fixedTop) of fixed elements in your
layout, such as navigation bars or headers. Unpoly will respect these sticky
elements when [revealing updated fragments](/up.reveal).

You should also [tell Unpoly](/up.viewport.config#config.viewportSelectors) when your application has more than one viewport,
so Unpoly can pick the right viewport to scroll for each fragment update.


\#\#\# Bootstrap integration

When using Bootstrap integration (`unpoly-bootstrap3.js` and `unpoly-bootstrap3.css`)
Unpoly will automatically be aware of sticky Bootstrap components such as
[fixed navbar](https://getbootstrap.com/examples/navbar-fixed-top/).

@module up.viewport
###
up.viewport = do ->

  u = up.util
  e = up.element
  f = up.fragment

  ###**
  Configures the application layout.

  @property up.viewport.config
  @param {Array} [config.viewportSelectors]
    An array of CSS selectors that find viewports
    (containers that scroll their contents).
  @param {Array} [config.fixedTop]
    An array of CSS selectors that find elements fixed to the
    top edge of the screen (using `position: fixed`).
    See [`[up-fixed="top"]`](/up-fixed-top) for details.
  @param {Array} [config.fixedBottom]
    An array of CSS selectors that find elements fixed to the
    bottom edge of the screen (using `position: fixed`).
    See [`[up-fixed="bottom"]`](/up-fixed-bottom) for details.
  @param {Array} [config.anchoredRight]
    An array of CSS selectors that find elements anchored to the
    right edge of the screen (using `right:0` with `position: fixed` or `position: absolute`).
    See [`[up-anchored="right"]`](/up-anchored-right) for details.
  @param {number} [config.revealSnap]
    When [revealing](/up.reveal) elements, Unpoly will scroll an viewport
    to the top when the revealed element is closer to the viewport's top edge
    than `config.revealSnap`.

    Set to `0` to disable snapping.
  @param {number} [config.revealPadding]
    The desired padding between a [revealed](/up.reveal) element and the
    closest [viewport](/up.viewport) edge (in pixels).
  @param {number} [config.revealMax]
    A number indicating how many top pixel rows of a high element to [reveal](/up.reveal).

    Defaults to 50% of the available window height.

    You may set this to `false` to always reveal as much of the element as the viewport allows.

    You may also pass a function that receives an argument `{ viewportRect, elementRect }` and returns
    a maximum height in pixel. Each given rectangle has properties `{ top, right, buttom, left, width, height }`.
  @param {number} [config.revealTop=false]
    Whether to always scroll a [revealing](/up.reveal) element to the top.

    By default Unpoly will scroll as little as possible to make the element visible.
  @param {number} [config.scrollSpeed=1]
    The speed of the scrolling motion when [scrolling](/up.scroll) with `{ behavior: 'smooth' }`.

    The default value (`1`) roughly corresponds to the speed of Chrome's
    [native smooth scrolling](https://developer.mozilla.org/en-US/docs/Web/API/ScrollToOptions/behavior).
  @stable
  ###
  config = new up.Config ->
    viewportSelectors: ['[up-viewport]', '[up-fixed]']
    fixedTop: ['[up-fixed~=top]']
    fixedBottom: ['[up-fixed~=bottom]']
    anchoredRight: ['[up-anchored~=right]', '[up-fixed~=top]', '[up-fixed~=bottom]', '[up-fixed~=right]']
    revealSnap: 200
    revealPadding: 0,
    revealTop: false,
    revealMax: -> 0.5 * window.innerHeight
    scrollSpeed: 1

  scrollingController = new up.MotionController('scrolling')

  reset = ->
    config.reset()
    scrollingController.reset()

  ###**
  Scrolls the given viewport to the given Y-position.

  A "viewport" is an element that has scrollbars, e.g. `<body>` or
  a container with `overflow-x: scroll`.

  \#\#\# Example

  This will scroll a `<div class="main">...</div>` to a Y-position of 100 pixels:

      up.scroll('.main', 100)

  \#\#\# Animating the scrolling motion

  The scrolling can (optionally) be animated.

      up.scroll('.main', 100, { behavior: 'smooth' })

  If the given viewport is already in a scroll animation when `up.scroll()`
  is called a second time, the previous animation will instantly jump to the
  last frame before the next animation is started.

  @function up.scroll
  @param {string|Element|jQuery} viewport
    The container element to scroll.
  @param {number} scrollPos
    The absolute number of pixels to set the scroll position to.
  @param {string}[options.behavior='auto']
    When set to `'auto'`, this will immediately scroll to the new position.

    When set to `'smooth'`, this will scroll smoothly to the new position.
  @param {number}[options.speed]
    The speed of the scrolling motion when scrolling with `{ behavior: 'smooth' }`.

    Defaults to `up.viewport.config.scrollSpeed`.
  @return {Promise}
    A promise that will be fulfilled when the scrolling ends.
  @internal
  ###
  scroll = (viewport, scrollTop, options = {}) ->
    viewport = f.get(viewport, options)
    motion = new up.ScrollMotion(viewport, scrollTop, options)
    scrollingController.startMotion(viewport, motion, options)

  ###**
  @function up.viewport.anchoredRight
  @internal
  ###
  anchoredRight = ->
    selector = config.anchoredRight.join(',')
    f.all(selector, { layer: 'root' })

  ###**
  Scroll's the given element's viewport so the first rows of the
  element are visible for the user.

  \#\#\# How Unpoly finds the viewport

  The viewport (the container that is going to be scrolled)
  is the closest parent of the element that is either:

  - the currently open [modal](/up.modal)
  - an element with the attribute `[up-viewport]`
  - the `<body>` element
  - an element matching the selector you have configured using `up.viewport.config.viewportSelectors.push('my-custom-selector')`

  \#\#\# Fixed elements obstructing the viewport

  Many applications have a navigation bar fixed to the top or bottom,
  obstructing the view on an element.

  You can make `up.reveal()` aware of these fixed elements
  so it can scroll the viewport far enough so the revealed element is fully visible.
  To make `up.reveal()` aware fixed elements you can either:

  - give the element an attribute [`up-fixed="top"`](/up-fixed-top) or [`up-fixed="bottom"`](up-fixed-bottom)
  - [configure default options](/up.viewport.config) for `fixedTop` or `fixedBottom`

  @function up.reveal
  @param {string|Element|jQuery} element
    The element to reveal.
  @param {number} [options.scrollSpeed=1]
    The speed of the scrolling motion when scrolling with `{ behavior: 'smooth' }`.

    The default value (`1`) roughly corresponds to the speed of Chrome's
    [native smooth scrolling](https://developer.mozilla.org/en-US/docs/Web/API/ScrollToOptions/behavior).

    Defaults to `up.viewport.config.scrollSpeed`.
  @param {string} [options.revealSnap]
    When the the revealed element would be closer to the viewport's top edge
    than this value, Unpoly will scroll the viewport to the top.

    Set to `0` to disable snapping.

    Defaults to `up.viewport.config.revealSnap`.
  @param {string|Element|jQuery} [options.viewport]
    The scrolling element to scroll.

    Defaults to the [given element's viewport](/up.viewport.closest).
  @param {boolean} [options.top]
    Whether to scroll the viewport so that the first element row aligns
    with the top edge of the viewport.

    Defaults to `up.viewport.config.revealTop`.
  @param {string}[options.behavior='auto']
    When set to `'auto'`, this will immediately scroll to the new position.

    When set to `'smooth'`, this will scroll smoothly to the new position.
  @param {number}[options.speed]
    The speed of the scrolling motion when scrolling with `{ behavior: 'smooth' }`.

    Defaults to `up.viewport.config.scrollSpeed`.
  @param {number} [options.padding]
    The desired padding between the revealed element and the
    closest [viewport](/up.viewport) edge (in pixels).

    Defaults to `up.viewport.config.revealPadding`.
  @param {number|boolean} [options.snap]
    Whether to snap to the top of the viewport if the new scroll position
    after revealing the element is close to the top edge.

    Defaults to `up.viewport.config.revealSnap`.
  @param {boolean} [options.peel=true]
    Whether to close overlays obscuring the layer of `element`.
  @return {Promise}
    A promise that fulfills when the element is revealed.

    When the scrolling is animated with `{ behavior: 'smooth' }`, the promise
    fulfills when the animation is finished.

    When the scrolling is not animated, the promise will fulfill
    in the next [microtask](https://jakearchibald.com/2015/tasks-microtasks-queues-and-schedules/).
  @stable
  ###
  reveal = (element, options) ->
    # copy options, since we will mutate it below
    options = u.options(options, peel: true)
    element = f.get(element, options)

    # Now that we have looked up the element with an option like { layer: 'any' },
    # the only layer relevant from here on is the element's layer.
    unless options.layer = up.layer.get(element)
      return up.failed.async('Cannot reveal a detached element')

    options.layer.peel() if options.peel

    motion = new up.RevealMotion(element, options)
    return scrollingController.startMotion(element, motion, options)

  ###**
  TODO: Docs
  ###
  doFocus = (element, options = {}) ->
    # First focus without scrolling, since we're going to use our custom scrolling
    # logic below.
    if up.browser.isIE11()
      viewport = closest(element)
      oldScrollTop = viewport.scrollTop
      element.focus()
      viewport.scrollTop = oldScrollTop
    else
      element.focus({ preventScroll: true })

    unless options.preventScroll
      # Use up.reveal() which scrolls far enough to ignore fixed nav bars
      # obstructing the focused element.
      reveal(element)

  tryFocus = (element, options) ->
    doFocus(element, options)
    return element == document.activeElement

  autofocus = (element, options) ->
    if autofocusElement = e.subtree(element, '[autofocus]')[0]
      doDocus(autofocusElement, options)
      return true

  isNativelyFocusable = (element) ->
    # IE11: In modern browsers we can check if element.tabIndex >= 0.
    # But IE11 returns 0 for all elements, including <div> etc.
    e.matches(element, 'a[href], button, textarea, input, select')

  makeFocusable = (element) ->
    # (1) Element#tabIndex is -1 for all non-interactive elements,
    #     whether or not the element has an [tabindex=-1] attribute.
    # (2) Element#tabIndex is 0 for interactive elements, like links,
    #     inputs or buttons. [up-clickable] elements also get a [tabindex=0].
    #     to participate in the regular tab order.
    unless element.hasAttribute('tabindex') || isNativelyFocusable(element)
      element.setAttribute('tabindex', '-1')

      # A11Y: OK to hide the focus ring of a non-interactive element.
      element.classList.add('up-focusable-content')

  ###**
  [Reveals](/up.reveal) an element matching the given `#hash` anchor.

  Other than the default behavior found in browsers, `up.revealHash` works with
  [multiple viewports](/up-viewport) and honors [fixed elements](/up-fixed-top) obstructing the user's
  view of the viewport.

  When the page loads initially, this function is automatically called with the hash from
  the current URL.

  If no element matches the given `#hash` anchor, a resolved promise is returned.

  \#\#\# Example

      up.revealHash('#chapter2')

  @function up.viewport.revealHash
  @param {string} hash
  @internal
  ###
  revealHash = (hash = location.hash, options) ->
    if match = firstHashTarget(hash, options)
      up.reveal(match, top: true)

  allSelector = ->
    # On Edge the document viewport can be changed from CSS
    [rootSelector(), config.viewportSelectors...].join(',')

  ###**
  Returns the scrolling container for the given element.

  Returns the [document's scrolling element](/up.viewport.root)
  if no closer viewport exists.

  @function up.viewport.closest
  @param {string|Element|jQuery} target
  @return {Element}
  @experimental
  ###
  closest = (target, options = {}) ->
    element = f.get(target, options)
    # Use up.element.closest() which searches across layer boundaries.
    # It is OK to find a viewport in a parent layer. Layers without its
    # own viewport (like popups) are scrolled by the parent layer's viewport.
    e.closest(element, allSelector())

  ###**
  Returns a jQuery collection of all the viewports contained within the
  given selector or element.

  @function up.viewport.subtree
  @param {string|Element|jQuery} target
  @return List<Element>
  @internal
  ###
  getSubtree = (element, options = {}) ->
    element = f.get(element, options)
    e.subtree(element, allSelector())

  getAround = (element, options = {}) ->
    element = f.get(element, options)
    e.around(element, allSelector())

  ###**
  Returns a list of all the viewports on the current layer.

  @function up.viewport.all
  @internal
  ###
  getAll = (options = {}) ->
    f.all(allSelector(), options)

  rootSelector = ->
    # The spec says this should be <html> in standards mode
    # and <body> in quirks mode. However, it is currently (2018-07)
    # always <body> in Webkit browsers (not Blink). Luckily Webkit
    # also supports document.scrollingElement.
    if element = document.scrollingElement
      element.tagName
    else
      # IE11
      'html'

  ###**
  Return the [scrolling element](https://developer.mozilla.org/en-US/docs/Web/API/document/scrollingElement)
  for the browser's main content area.

  @function up.viewport.root
  @return {Element}
  @experimental
  ###
  getRoot = ->
    document.querySelector(rootSelector())

  rootWidth = ->
    # This should happen on the <html> element, regardless of document.scrollingElement
    e.root.clientWidth

  rootHeight = ->
  # This should happen on the <html> element, regardless of document.scrollingElement
    e.root.clientHeight

  isRoot = (element) ->
    e.matches(element, rootSelector())

  ###**
  Returns whether the root viewport is currently showing a vertical scrollbar.

  Note that this returns `false` if the root viewport scrolls vertically but the browser
  shows no visible scroll bar at rest, e.g. on mobile devices that only overlay a scroll
  indicator while scrolling.

  @function up.viewport.rootHasReducedWidthFromScrollbar
  @internal
  ###
  rootHasReducedWidthFromScrollbar = ->
    # We could also check if scrollHeight > offsetHeight for the document viewport.
    # However, we would also need to check overflow-y for that element.
    # Also we have no control whether developers set the property on <body> or <html>.
    # https://tylercipriani.com/blog/2014/07/12/crossbrowser-javascript-scrollbar-detection/
    window.innerWidth > document.documentElement.offsetWidth

  ###**
  Returns the element that controls the `overflow-y` behavior for the
  [document viewport](/up.viewport.root()).

  @function up.viewport.rootOverflowElement
  @internal
  ###
  rootOverflowElement = ->
    body = document.body
    html = document.documentElement

    element = u.find([html, body], wasChosenAsOverflowingElement)
    element || getRoot()

  ###**
  Returns whether the given element was chosen as the overflowing
  element by the developer.

  We have no control whether developers set the property on <body> or
  <html>. The developer also won't know what is going to be the
  [scrolling element](/up.viewport.root) on the user's browser.

  @function wasChosenAsOverflowingElement
  @internal
  ###
  wasChosenAsOverflowingElement = (element) ->
    overflowY = e.style(element, 'overflow-y')
    overflowY == 'auto' || overflowY == 'scroll'

  ###**
  Returns the width of a scrollbar.

  This only runs once per page load.

  @function up.viewport.scrollbarWidth
  @internal
  ###
  scrollbarWidth = u.memoize ->
    # This is how Bootstrap does it also:
    # https://github.com/twbs/bootstrap/blob/c591227602996c542b9fd0cb65cff3cc9519bdd5/dist/js/bootstrap.js#L1187
    outerStyle =
      position:  'absolute'
      top:       '0'
      left:      '0'
      width:     '100px'
      height:    '100px' # Firefox needs at least 100px to show a scrollbar
      overflowY: 'scroll'
    outer = up.element.affix(document.body, '[up-viewport]', { style: outerStyle })
    width = outer.offsetWidth - outer.clientWidth
    up.element.remove(outer)
    width

  scrollTopKey = (viewport) ->
    up.fragment.toTarget(viewport)

  ###**
  Returns a hash with scroll positions.

  Each key in the hash is a viewport selector. The corresponding
  value is the viewport's top scroll position:

      up.viewport.scrollTops()
      => { '.main': 0, '.sidebar': 73 }

  @function up.viewport.scrollTops
  @return Object<string, number>
  @internal
  ###
  scrollTops = (options = {}) ->
    u.mapObject getAll(options), (viewport) ->
      [scrollTopKey(viewport), viewport.scrollTop]

  ###**
  @function up.viewport.fixedElements
  @internal
  ###
  fixedElements = (root = document) ->
    queryParts = ['[up-fixed]'].concat(config.fixedTop).concat(config.fixedBottom)
    root.querySelectorAll(queryParts.join(','))

  ###**
  Saves the top scroll positions of all viewports in the current layer.

  The scroll positions will be associated with the current URL.
  They can later be restored by calling [`up.viewport.restoreScroll()`](/up.viewport.restoreScroll)
  at the same URL, or by following a link with an [`[up-restore-scroll]`](/a-up-follow#up-restore-scroll)
  attribute.

  Unpoly automatically saves scroll positions before a [fragment update](/up.replace)
  you will rarely need to call this function yourself.

  \#\#\# Examples

  Should you need to save the current scroll positions outside of a [fragment update](/up.replace),
  you may call:

      up.viewport.saveScroll()

  Instead of saving the current scroll positions for the current URL, you may also pass another
  url or vertical scroll positionsfor each viewport:

      up.viewport.saveScroll({
        url: '/inbox',
        tops: {
          'body': 0,
          '.sidebar', 100,
          '.main', 320
        }
      })

  @function up.viewport.saveScroll
  @param {string} [options.location]
    The URL for which to save scroll positions.
    If omitted, the current browser location is used.
  @param {string} [options.layer]
    The layer for which to save scroll positions.
    If omitted, positions for the current layer will be saved.
  @param {Object<string, number>} [options.tops]
    An object mapping viewport selectors to vertical scroll positions in pixels.
  @experimental
  ###
  saveScroll = (args...) ->
    [viewports, options] = parseOptions(args)
    if url = (options.location || options.layer.location)
      tops = options.tops ? getScrollTops(viewports)
      options.layer.lastScrollTops.set(url, tops)

  getScrollTops = (viewports) ->
    u.mapObject viewports, (viewport) -> [scrollTopKey(viewport), viewport.scrollTop]

  ###**
  Restores [previously saved](/up.viewport.saveScroll) scroll positions of viewports
  viewports configured in `up.viewport.config.viewportSelectors`.

  Unpoly automatically restores scroll positions when the user presses the back button.
  You can disable this behavior by setting [`up.history.config.restoreScroll = false`](/up.history.config).

  @function up.viewport.restoreScroll
  @param {Element} [viewport]
  @param {up.Layer|string} [options.layer]
    The layer on which to restore scroll positions.
  @return {Promise}
    A promise that will be fulfilled once scroll positions have been restored.
  @experimental
  ###
  restoreScroll = (args...) ->
    [viewports, options] = parseOptions(args)
    url = options.layer.location
    scrollTopsForURL = options.layer.lastScrollTops.get(url) || {}
    up.puts 'up.viewport.restoreScroll()', 'Restoring scroll positions for URL %s to %o', u.urlWithoutHost(url), scrollTopsForURL
    return setScrollTops(viewports, scrollTopsForURL)

  parseOptions = (args) ->
    options = u.copy(u.extractOptions(args))
    options.layer = up.layer.get(options)
    if args[0]
      viewports = [closest(args[0], options)]
    else if options.around
      # This is relevant for up.history. When we go back for replace <body>
      # and then restore the scroll tops of all viewports in <body>.
      viewports = getAround(options.around, options)
    else
      viewports = getAll(options)
    return [viewports, options]

  resetScroll = (args...) ->
    [viewports, options] = parseOptions(args)
    return setScrollTops(viewports, {})

  setScrollTops = (viewports, tops) ->
    allScrollPromises = u.map viewports, (viewport) ->
      key = scrollTopKey(viewport)
      scrollTop = tops[key] || 0
      scroll(viewport, scrollTop, duration: 0)
    return Promise.all(allScrollPromises)

  ###**
  @internal
  ###
  absolutize = (element, options = {}) ->
    viewport = closest(element)

    viewportRect = viewport.getBoundingClientRect()
    originalRect = element.getBoundingClientRect()

    boundsRect = new up.Rect
      left: originalRect.left - viewportRect.left
      top: originalRect.top - viewportRect.top
      width: originalRect.width
      height: originalRect.height

    # Allow the caller to run code before we start shifting elements around.
    options.afterMeasure?()

    e.setStyle element,
      # If the element had a layout context before, make sure the
      # ghost will have layout context as well (and vice versa).
      position: if element.style.position == 'static' then 'static' else 'relative'
      top:    'auto' # CSS default
      right:  'auto' # CSS default
      bottom: 'auto' # CSS default
      left:   'auto' # CSS default
      width:  '100%' # stretch to the <up-bounds> width we set below
      height: '100%' # stretch to the <up-bounds> height we set below

    # Wrap the ghost in another container so its margin can expand
    # freely. If we would position the element directly (old implementation),
    # it would gain a layout context which cannot be crossed by margins.
    bounds = e.createFromSelector('up-bounds')
    # Insert the bounds object before our element, then move element into it.
    e.insertBefore(element, bounds)
    bounds.appendChild(element)

    moveBounds = (diffX, diffY) ->
      boundsRect.left += diffX
      boundsRect.top += diffY
      e.setStyle(bounds, boundsRect)

    # Position the bounds initially
    moveBounds(0, 0)

    # In theory, element should not have moved visually. However, element
    # (or a child of element) might collapse its margin against a previous
    # sibling element, and now that it is absolute it does not have the
    # same sibling. So we manually correct element's top position so it aligns
    # with the previous top position.
    newElementRect = element.getBoundingClientRect()
    moveBounds(originalRect.left - newElementRect.left, originalRect.top - newElementRect.top)

    u.each(fixedElements(element), e.fixedToAbsolute)

    bounds: bounds
    moveBounds: moveBounds

  ###**
  Marks this element as a scrolling container ("viewport").

  Apply this attribute if your app uses a custom panel layout with fixed positioning
  instead of scrolling `<body>`. As an alternative you can also push a selector
  matching your custom viewport to the `up.viewport.config.viewportSelectors` array.

  [`up.reveal()`](/up.reveal) will always try to scroll the viewport closest
  to the element that is being revealed. By default this is the `<body>` element.

  \#\#\# Example

  Here is an example for a layout for an e-mail client, showing a list of e-mails
  on the left side and the e-mail text on the right side:

      .side {
        position: fixed;
        top: 0;
        bottom: 0;
        left: 0;
        width: 100px;
        overflow-y: scroll;
      }

      .main {
        position: fixed;
        top: 0;
        bottom: 0;
        left: 100px;
        right: 0;
        overflow-y: scroll;
      }

  This would be the HTML (notice the `up-viewport` attribute):

      <div class=".side" up-viewport>
        <a href="/emails/5001" up-target=".main">Re: Your invoice</a>
        <a href="/emails/2023" up-target=".main">Quote for services</a>
        <a href="/emails/9002" up-target=".main">Fwd: Room reservation</a>
      </div>

      <div class="main" up-viewport>
        <h1>Re: Your Invoice</h1>
        <p>
          Lorem ipsum dolor sit amet, consetetur sadipscing elitr.
          Stet clita kasd gubergren, no sea takimata sanctus est.
        </p>
      </div>

  @selector [up-viewport]
  @stable
  ###

  ###**
  Marks this element as being fixed to the top edge of the screen
  using `position: fixed`.

  When [following a fragment link](/a-up-target), the viewport is scrolled
  so the targeted element becomes visible. By using this attribute you can make
  Unpoly aware of fixed elements that are obstructing the viewport contents.
  Unpoly will then scroll the viewport far enough that the revealed element is fully visible.

  Instead of using this attribute,
  you can also configure a selector in `up.viewport.config.fixedTop`.

  \#\#\# Example

      <div class="top-nav" up-fixed="top">...</div>

  @selector [up-fixed=top]
  @stable
  ###

  ###**
  Marks this element as being fixed to the bottom edge of the screen
  using `position: fixed`.

  When [following a fragment link](/a-up-target), the viewport is scrolled
  so the targeted element becomes visible. By using this attribute you can make
  Unpoly aware of fixed elements that are obstructing the viewport contents.
  Unpoly will then scroll the viewport far enough that the revealed element is fully visible.

  Instead of using this attribute,
  you can also configure a selector in `up.viewport.config.fixedBottom`.

  \#\#\# Example

      <div class="bottom-nav" up-fixed="bottom">...</div>

  @selector [up-fixed=bottom]
  @stable
  ###


  ###**
  Marks this element as being anchored to the right edge of the screen,
  typically fixed navigation bars.

  Since [modal dialogs](/up.modal) hide the document scroll bar,
  elements anchored to the right appear to jump when the dialog opens or
  closes. Applying this attribute to anchored elements will make Unpoly
  aware of the issue and adjust the `right` property accordingly.

  You should give this attribute to layout elements
  with a CSS of `right: 0` with `position: fixed` or `position:absolute`.

  Instead of giving this attribute to any affected element,
  you can also configure a selector in `up.viewport.config.anchoredRight`.

  \#\#\# Example

  Here is the CSS for a navigation bar that is anchored to the top edge of the screen:

      .top-nav {
         position: fixed;
         top: 0;
         left: 0;
         right: 0;
       }

  By adding an `up-anchored="right"` attribute to the element, we can prevent the
  `right` edge from jumping when a [modal dialog](/up.modal) opens or closes:

      <div class="top-nav" up-anchored="right">...</div>

  @selector [up-anchored=right]
  @stable
  ###

  ###**
  @function up.viewport.firstHashTarget
  @internal
  ###
  firstHashTarget = (hash, options = {}) ->
    if hash = pureHash(hash)
      selector = [
        # Match an <* id="hash">
        e.attributeSelector('id', hash),
        # Match an <a name="hash">
        'a' + e.attributeSelector('name', hash)
      ].join(',')
      f.get(selector, options)

  ###**
  Returns `'foo'` if the hash is `'#foo'`.

  @function pureHash
  @internal
  ###
  pureHash = (value) ->
    return value?.replace(/^#/, '')

  userScrolled = false
  up.on 'scroll', { once: true }, -> userScrolled = true

  up.on 'up:app:boot', ->
    # When the initial URL contains an #anchor link, the browser will automatically
    # reveal a matching fragment. We want to override that behavior with our own,
    # so we can honor configured obstructions. Since we cannot disable the automatic
    # browser behavior we need to ensure our code runs after it.
    #
    # In Chrome, when reloading, the browser behavior happens before DOMContentLoaded.
    # However, when we follow a link with an #anchor URL, the browser
    # behavior happens *after* DOMContentLoaded. Hence we wait one more task.
    u.task ->
      # If the user has scrolled while the page was loading, we will
      # not reset their scroll position by revealing the #anchor fragment.
      unless userScrolled
        revealHash()

  up.on window, 'hashchange', -> revealHash()

  up.on 'up:framework:reset', reset

  u.literal
    reveal: reveal
    revealHash: revealHash
    firstHashTarget: firstHashTarget
    scroll: scroll
    config: config
    get: closest
    subtree: getSubtree
    around: getAround
    all: getAll
    rootSelector: rootSelector
    get_root: getRoot
    rootWidth: rootWidth
    rootHeight: rootHeight
    rootHasReducedWidthFromScrollbar: rootHasReducedWidthFromScrollbar
    rootOverflowElement: rootOverflowElement
    isRoot: isRoot
    scrollbarWidth: scrollbarWidth
    scrollTops: scrollTops
    saveScroll: saveScroll
    restoreScroll: restoreScroll
    resetScroll: resetScroll
    anchoredRight: anchoredRight
    fixedElements: fixedElements
    absolutize: absolutize
    focus: doFocus
    tryFocus: tryFocus
    autofocus: autofocus
    makeFocusable: makeFocusable

up.focus = up.viewport.focus
up.scroll = up.viewport.scroll
up.reveal = up.viewport.reveal

