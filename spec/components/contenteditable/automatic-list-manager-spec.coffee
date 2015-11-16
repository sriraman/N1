
xdescribe "AutomaticListManager", ->
  beforeEach ->
    @ce = new ContenteditableTestHarness

  it "Creates ordered lists", ->
    @ce.type ['1', '.', ' ']
    @ce.expectHTML "<ol><li></li></ol>"
    @ce.expectSelection (dom) ->
      dom.querySelectorAll("li")[0]

  it "Undoes ordered list creation with backspace", ->
    @ce.type ['1', '.', ' ', 'backspace']
    @ce.expectHTML "1.&nbsp;"
    @ce.expectSelection (dom) ->
      node: dom.childNodes[0]
      offset: 3

  it "Creates unordered lists with star", ->
    @ce.type ['*', ' ']
    @ce.expectHTML "<ul><li></li></ul>"
    @ce.expectSelection (dom) ->
      dom.querySelectorAll("li")[0]

  it "Undoes unordered list creation with backspace", ->
    @ce.type ['*', ' ', 'backspace']
    @ce.expectHTML "*&nbsp;"
    @ce.expectSelection (dom) ->
      node: dom.childNodes[0]
      offset: 2

  it "Creates unordered lists with dash", ->
    @ce.type ['-', ' ']
    @ce.expectHTML "<ul><li></li></ul>"
    @ce.expectSelection (dom) ->
      dom.querySelectorAll("li")[0]

  it "Undoes unordered list creation with backspace", ->
    @ce.type ['-', ' ', 'backspace']
    @ce.expectHTML "-&nbsp;"
    @ce.expectSelection (dom) ->
      node: dom.childNodes[0]
      offset: 2

  it "create a single item then delete it with backspace", ->
    @ce.type ['-', ' ', 'a', 'left', 'backspace']
    @ce.expectHTML "a"
    @ce.expectSelection (dom) ->
      node: dom.childNodes[0]
      offset: 0

  it "create a single item then delete it with tab", ->
    @ce.type ['-', ' ', 'a', 'shift-tab']
    @ce.expectHTML "a"
    @ce.expectSelection (dom) -> dom.childNodes[0]
      node: dom.childNodes[0]
      offset: 1

  describe "when creating two items in a list", ->
    it "creates two items with enter at end", ->
      @ce.type ['-', ' ', 'a', 'enter', 'b']
      @ce.expectHTML "<ul><li>a</li><li>b</li></ul>"
      @ce.expectSelection (dom) ->
        node: dom.querySelectorAll('li')[1].childNodes[0]
        offset: 1

    it "backspace from the start of the 1st item outdents", ->

    it "backspace from the start of the 2nd item outdents", ->

    it "shift-tab from the start of the 1st item outdents", ->

    it "shift-tab from the start of the 2nd item outdents", ->

    it "shift-tab from the end of the 1st item outdents", ->

    it "shift-tab from the end of the 2nd item outdents", ->
