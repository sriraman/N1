ContenteditableTestHarness = require './contenteditable-test-harness'

fdescribe "ListManager", ->
  beforeEach ->
    # console.log "--> Before each"
    @ce = new ContenteditableTestHarness
    # div = document.querySelector("div[contenteditable]")
    # console.log div
    # console.log div?.innerHTML
    # console.log "Done before each"

  afterEach ->
    # console.log "<-- After each"
    @ce.cleanup()

  ffit "Creates ordered lists", -> waitsForPromise =>
    @ce.keys(['1', '.', ' ']).then =>
      # console.log "Keys typed"
      @ce.expectHTML "<ol><li></li></ol>"
      @ce.expectSelection (dom) ->
        node: dom.querySelectorAll("li")[0]

  it "Undoes ordered list creation with backspace", ->
    @ce.keys ['1', '.', ' ', 'backspace']
    @ce.expectHTML "1.&nbsp;"
    @ce.expectSelection (dom) ->
      node: dom.childNodes[0]
      offset: 3

  it "Creates unordered lists with star", ->
    @ce.keys ['*', ' ']
    @ce.expectHTML "<ul><li></li></ul>"
    @ce.expectSelection (dom) ->
      node: dom.querySelectorAll("li")[0]

  it "Undoes unordered list creation with backspace", ->
    @ce.keys ['*', ' ', 'backspace']
    @ce.expectHTML "*&nbsp;"
    @ce.expectSelection (dom) ->
      node: dom.childNodes[0]
      offset: 2

  it "Creates unordered lists with dash", ->
    @ce.keys ['-', ' ']
    @ce.expectHTML "<ul><li></li></ul>"
    @ce.expectSelection (dom) ->
      node: dom.querySelectorAll("li")[0]

  it "Undoes unordered list creation with backspace", ->
    @ce.keys ['-', ' ', 'backspace']
    @ce.expectHTML "-&nbsp;"
    @ce.expectSelection (dom) ->
      node: dom.childNodes[0]
      offset: 2

  it "create a single item then delete it with backspace", ->
    @ce.keys ['-', ' ', 'a', 'left', 'backspace']
    @ce.expectHTML "a"
    @ce.expectSelection (dom) ->
      node: dom.childNodes[0]
      offset: 0

  it "create a single item then delete it with tab", ->
    @ce.keys ['-', ' ', 'a', 'shift-tab']
    @ce.expectHTML "a"
    @ce.expectSelection (dom) -> dom.childNodes[0]
      node: dom.childNodes[0]
      offset: 1

  describe "when creating two items in a list", ->
    beforeEach ->
      @twoItemKeys = ['-', ' ', 'a', 'enter', 'b']

    it "creates two items with enter at end", ->
      @ce.keys @twoItemKeys
      @ce.expectHTML "<ul><li>a</li><li>b</li></ul>"
      @ce.expectSelection (dom) ->
        node: dom.querySelectorAll('li')[1].childNodes[0]
        offset: 1

    it "backspace from the start of the 1st item outdents", ->
      @ce.keys @twoItemKeys.concat ['left', 'up', 'backspace']

    it "backspace from the start of the 2nd item outdents", ->
      @ce.keys @twoItemKeys.concat ['left', 'backspace']

    it "shift-tab from the start of the 1st item outdents", ->
      @ce.keys @twoItemKeys.concat ['left', 'up', 'shift-tab']

    it "shift-tab from the start of the 2nd item outdents", ->
      @ce.keys @twoItemKeys.concat ['left', 'shift-tab']

    it "shift-tab from the end of the 1st item outdents", ->
      @ce.keys @twoItemKeys.concat ['up', 'shift-tab']

    it "shift-tab from the end of the 2nd item outdents", ->
      @ce.keys @twoItemKeys.concat ['shift-tab']

    it "backspace from the end of the 1st item doesn't outdent", ->
      @ce.keys @twoItemKeys.concat ['up', 'backspace']

    it "backspace from the end of the 2nd item doesn't outdent", ->
      @ce.keys @twoItemKeys.concat ['backspace']

  describe "multi-depth bullets", ->
    it "creates multi level bullet when tabbed in", ->
      @ce.keys ['-', ' ', 'a', 'tab']

    it "creates multi level bullet when tabbed in", ->
      @ce.keys ['-', ' ', 'tab', 'a']

    it "returns to single level bullet on backspace", ->
      @ce.keys ['-', ' ', 'a', 'tab', 'left', 'backspace']

    it "returns to single level bullet on shift-tab", ->
      @ce.keys ['-', ' ', 'a', 'tab', 'shift-tab']
