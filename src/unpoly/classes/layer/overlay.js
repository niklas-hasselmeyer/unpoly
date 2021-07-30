const e = up.element
const u = up.util

/***
@class up.Layer
*/
up.Layer.Overlay = class Overlay extends up.Layer {

  /***
  The link or form element that opened this overlay.

  @property up.Layer#origin
  @param {Element} origin
  @stable
  */

  /***
  The [size](/customizing-overlays#overlay-sizes) of this overlay.

  Returns a string like `'medium'` or `'large'`.

  @property up.Layer#size
  @param {Element} size
  @stable
  */

  /***
  The [position](/customizing-overlays#popup-position) of this popup overlay.

  Returns a string like `'top'` or `'left'`.

  @property up.Layer#position
  @param {Element} align
  @stable
  */

  /***
  The [alignment](/customizing-overlays#popup-position) of this popup overlay.

  Returns a string like `'left'` or `'right'`.

  @property up.Layer#align
  @param {Element} align
  @stable
  */

  keys() {
    return super.keys().concat([
      'position',
      'align',
      'size',
      'origin', // for tethered anchor element
      'class',
      'backdrop',
      'openAnimation',
      'closeAnimation',
      'openDuration',
      'closeDuration',
      'openEasing',
      'closeEasing',
      'backdropOpenAnimation',
      'backdropCloseAnimation',
      'dismissable',
      'dismissLabel',
      'dismissAriaLabel',
      'onOpened',
      'onAccept',
      'onAccepted',
      'onDismiss',
      'onDismissed',
      'acceptEvent',
      'dismissEvent',
      'acceptLocation',
      'dismissLocation',
      'opening' // internal flag to know that the layer is being opened
    ])
  }

  constructor(options) {
    super(options)

    if (this.dismissable === true) {
      this.dismissable = ['button', 'key', 'outside']
    } else if (this.dismissable === false) {
      this.dismissable = []
    } else {
      this.dismissable = u.splitValues(this.dismissable)
    }

    if (this.acceptLocation) {
      this.acceptLocation = new up.URLPattern(this.acceptLocation)
    }

    if (this.dismissLocation) {
      this.dismissLocation = new up.URLPattern(this.dismissLocation)
    }
  }

  callback(name) {
    // Only binds the callback to the layer instance.
    // Note if the callback was created by an UJS attribute like [up-on-accepted], the
    // callback is already bound to the origin element to mimic the behavior of built-in
    // handler attributes like [onclick]. In that case our additional bind() will have
    // no effect.
    //
    // The up.layer.current value within a callback is controlled by the event
    // emission in up.Change.OpenLayer and up.Change.CloseLayer
    let fn = this[name]
    if (fn) {
      return fn.bind(this)
    }
  }

  createElement(parentElement) {
    this.nesting ||= this.suggestVisualNesting();
    const elementAttrs = u.compactObject(u.pick(this, ['align', 'position', 'size', 'class', 'nesting']))
    this.element = this.affixPart(parentElement, null, elementAttrs)
  }

  createBackdropElement(parentElement) {
    this.backdropElement = this.affixPart(parentElement, 'backdrop')
  }

  createViewportElement(parentElement) {
    // Give the viewport element an [up-viewport] attribute so it will be found
    // by up.viewport.get().
    this.viewportElement = this.affixPart(parentElement, 'viewport', {'up-viewport': ''})
  }

  createBoxElement(parentElement) {
    this.boxElement = this.affixPart(parentElement, 'box')
  }

  createContentElement(parentElement, content) {
    this.contentElement = this.affixPart(parentElement, 'content')
    this.contentElement.appendChild(content)
  }

  createDismissElement(parentElement) {
    this.dismissElement = this.affixPart(parentElement, 'dismiss', {
      'up-dismiss': '":button"', // value must be JSON
      'aria-label': this.dismissAriaLabel
    })
    // Since the dismiss button already has an accessible [aria-label]
    // we hide the "X" label from screen readers.
    return e.affix(this.dismissElement, 'span[aria-hidden="true"]', { text: this.dismissLabel })
  }

  affixPart(parentElement, part, options = {}) {
    return e.affix(parentElement, this.selector(part), options)
  }

  static selector(part) {
    return u.compact(['up', this.mode, part]).join('-')
  }

  suggestVisualNesting() {
    const { parent } = this
    if (this.mode === parent.mode) {
      return 1 + parent.suggestVisualNesting()
    } else {
      return 0
    }
  }

  setupHandlers() {
    super.setupHandlers()

    this.overlayFocus = new up.OverlayFocus(this)

    if (this.supportsDismissMethod('button')) {
      this.createDismissElement(this.getBoxElement())
    }

    if (this.supportsDismissMethod('outside')) {
      this.unbindParentClicked = this.parent.on('up:click', (event, element) => {
        // When our origin is clicked again, halt the click event
        // We achieve this by halting the click event.
        const originClicked = this.origin && this.origin.contains(element)
        this.onOutsideClicked(event, originClicked)
      })

      // If this overlay has its own viewport, a click outside the frame will hit
      // the viewport and not the parent element.
      if (this.viewportElement) {
        up.on(this.viewportElement, 'up:click', event => {
          // Don't react when a click into the overlay frame bubbles to the viewportElement
          if (event.target === this.viewportElement) {
            this.onOutsideClicked(event, true)
          }
        })
      }
    }

    if (this.supportsDismissMethod('key')) {
      this.unbindEscapePressed = up.event.onEscape(event => this.onEscapePressed(event))
    }

    // <a up-accept="value">OK</a>
    this.registerClickCloser('up-accept', (value, closeOptions) => {
      this.accept(value, closeOptions)
    })

    // <a up-dismiss="value">Cancel</a>
    this.registerClickCloser('up-dismiss', (value, closeOptions) => {
      this.dismiss(value, closeOptions)
    })

    up.migrate.registerLayerCloser?.(this)

    // let { userId } = await up.layer.open({ acceptEvent: 'user:show' })
    // registerEventCloser() will fill in this and arguments.
    this.registerEventCloser(this.acceptEvent, this.accept)
    this.registerEventCloser(this.dismissEvent, this.dismiss)
  }

  onOutsideClicked(event, halt) {
    if (halt) {
      up.event.halt(event)
    }
    this.dismiss(':outside')
  }

  onEscapePressed(event) {
    // All overlays listen to the Escape key being pressed, but only the front layer
    // should react. Note that we're using the *front* layer, not the *current* layer.
    // The current layer might be in the visual background, e.g. if a fragment is being
    // compiled in a background layer.
    if (this.isFront()) {
      let field = up.form.focusedField()
      if (field) {
        // Allow screen reader users to get back to a state where they can dismiss the
        // modal with escape.
        field.blur()
      } else if (this.supportsDismissMethod('key')) {
        up.event.halt(event)
        this.dismiss(':key')
      }
    }
  }

  registerClickCloser(attribute, closeFn) {
    // Allow the fallbacks to be both vanilla links and Unpoly [up-target] links
    this.on('up:click', `[${attribute}]`, function(event) {
      // Since we're defining this handler on up.Overlay, we will not prevent
      // a link from being followed on the root layer.
      up.event.halt(event)

      const origin = event.target
      const value = e.jsonAttr(origin, attribute)
      const closeOptions = { origin }
      const parser = new up.OptionsParser(closeOptions, origin)
      parser.booleanOrString('animation')
      parser.string('easing')
      parser.number('duration')
      parser.string('confirm')

      closeFn(value, closeOptions)
    })
  }

  registerEventCloser(eventTypes, closeFn) {
    if (!eventTypes) { return; }
    return this.on(eventTypes, event => {
      event.preventDefault()
      closeFn.call(this, event)
    })
  }

  tryAcceptForLocation() {
    this.tryCloseForLocation(this.acceptLocation, this.accept)
  }

  tryDismissForLocation() {
    this.tryCloseForLocation(this.dismissLocation, this.dismiss)
  }

  tryCloseForLocation(urlPattern, closeFn) {
    let location, resolution
    if (urlPattern && (location = this.location) && (resolution = urlPattern.recognize(location))) {
      // resolution now contains named capture groups, e.g. when
      // '/decks/:deckId/cards/:cardId' is matched against
      // '/decks/123/cards/456' resolution is { deckId: 123, cardId: 456 }.
      const closeValue = { ... resolution, location }
      closeFn.call(this, closeValue)
    }
  }

  teardownHandlers() {
    super.teardownHandlers()
    this.unbindParentClicked?.()
    this.unbindEscapePressed?.()
    this.overlayFocus.teardown()
  }

  /***
  Destroys the elements that make up this overlay.

  @function up.Layer.prototype.destroyElements
  @param {string|Function(Element, Object)} [options.animation=this.closeAnimation]
  @param {number} [options.duration=this.closeDuration]
  @param {string} [options.easing=this.closeEasing]
  @param {Function} [options.onFinished]
    A callback that will run when the elements have been removed from the DOM.
    If the destruction is animated, the callback will run after the animation has finished.
  @return {Promise}
    A resolved promise.
  @internal
  */
  destroyElements(options) {
    const animation = () => {
      return this.startCloseAnimation(options)
    }

    const onFinished = () => {
      this.onElementsRemoved() // callback for layer implementations that need to clean up
      options.onFinished?.() // callback for callers of up.layer.dismiss/accept()
    }

    // Do not re-use `options`, or we would call startCloseAnimation(animation: startCloseAnimation)!
    const destroyOptions = { ...options, animation, onFinished, log: false }
    up.destroy(this.element, destroyOptions)
  }

  onElementsRemoved() {}
    // optional callback

  startAnimation(options = {}) {
    const boxDone = up.animate(this.getBoxElement(), options.boxAnimation, options)

    // If we don't animate the box, we don't animate the backdrop
    let backdropDone
    if (this.backdrop && !up.motion.isNone(options.boxAnimation)) {
      backdropDone = up.animate(this.backdropElement, options.backdropAnimation, options)
    }

    // Promise.all() ignores non-Thenables in the given array
    return Promise.all([boxDone, backdropDone])
  }

  startOpenAnimation(options = {}) {
    return this.startAnimation({
      boxAnimation: options.animation ?? this.evalOption(this.openAnimation),
      backdropAnimation: 'fade-in',
      easing: options.easing || this.openEasing,
      duration: options.duration || this.openDuration
    }).then(() => {
      return this.wasEverVisible = true
    })
  }

  startCloseAnimation(options = {}) {
    const boxAnimation = this.wasEverVisible && (options.animation ?? this.evalOption(this.closeAnimation))

    return this.startAnimation({
      boxAnimation,
      backdropAnimation: 'fade-out',
      easing: options.easing || this.closeEasing,
      duration: options.duration || this.closeDuration
    })
  }

  accept(value = null, options = {}) {
    return this.executeCloseChange('accept', value, options)
  }

  dismiss(value = null, options = {}) {
    return this.executeCloseChange('dismiss', value, options)
  }

  supportsDismissMethod(method) {
    return u.contains(this.dismissable, method)
  }

  executeCloseChange(verb, value, options) {
    options = { ...options, verb, value, layer: this }
    return new up.Change.CloseLayer(options).execute()
  }

  getFirstSwappableElement() {
    return this.getContentElement().children[0]
  }

  toString() {
    return `${this.mode} overlay`
  }
}