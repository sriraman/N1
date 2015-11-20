_ = require 'underscore'
React = require 'react/addons'
TimeOverride = require '../../time-override'
NylasTestUtils = require '../../nylas-test-utils'

{Contenteditable} = require 'nylas-component-kit'

###
Public: Easily test contenteditable interactions

Create a new instance of this on each test. It will render a new
Contenteditable into the document wrapped around a class that can keep
track of its state.

For example

```coffee
beforeEach ->
  @ce = new ContenteditableTestHarness

it "can create an ordered list", ->
  @ce.keys ['1', '.', ' ']
  @ce.expectHTML "<ol><li></li></ol>"
  @ce.expectSelection (dom) ->
    node: dom.querySelectorAll("li")[0]

afterEach ->
  @ce.cleanup()

```

**Be sure to call `cleanup` after each test**

###
class ContenteditableTestHarness
  constructor: ({@props, @initialValue}={}) ->
    @props ?= {}
    @initialValue ?= ""

    @wrap = NylasTestUtils.renderIntoDocument(
      <Wrap ceProps={@props} initialValue={@initialValue} />
    )

  cleanup: ->
    NylasTestUtils.removeFromDocument(@wrap)

  keys: (keyStrokes=[]) -> new Promise (resolve, reject) =>
    TimeOverride.disableSpies()
    # console.log "About to input keys"
    # div = document.querySelector("div[contenteditable]")
    # console.log div
    # console.log div?.innerHTML
    # console.log document.activeElement
    # console.log keyStrokes
    @getDOM().focus()
    NylasEnv.spectron.client.keys(keyStrokes)
    window.setTimeout ->
      resolve()
      # console.log "After keys!"
      # NylasEnv.openDevTools()
      # window.setTimeout ->
      #   div = document.querySelector("div[contenteditable]")
      #   console.log(div)
      #   console.log div?.innerHTML
      #   NylasEnv.spectron.client.getHTML("div[contenteditable]").then (html) ->
      #     console.log html
      #   TimeOverride.enableSpies()
      #   resolve()
      # , 100000
    , 200

  expectHTML: (expectedHTML) ->
    expect(@wrap.state.value).toBe expectedHTML

  expectSelection: (callback) ->
    expectSel = callback(@getDOM())

    anchorNode = expectSel.anchorNode ? expectSel.node ? "No anchorNode found"
    focusNode = expectSel.focusNode ? expectSel.node ? "No focusNode found"
    anchorOffset = expectSel.anchorOffset ? expectSel.offset ? 0
    focusOffset = expectSel.focusOffset ? expectSel.offset ? 0

    selection = document.getSelection()

    expect(selection.anchorNode).toBe anchorNode
    expect(selection.focusNode).toBe focusNode
    expect(selection.anchorOffset).toBe anchorOffset
    expect(selection.focusOffset).toBe focusOffset

  getDOM: ->
    React.findDOMNode(@wrap.refs["ceWrap"].refs["contenteditable"])

class Wrap extends React.Component
  @displayName: "wrap"

  constructor: (@props) ->
    @state = value: @props.initialValue

  render: ->
    userOnChange = @props.ceProps.onChange ? ->
    props = _.clone(@props.ceProps)
    props.onChange = (event) =>
      userOnChange(event)
      @onChange(event)
    props.value = @state.value
    props.ref = "ceWrap"

    <Contenteditable {...props} />

  onChange: (event) ->
    @setState value: event.target.value

  componentDidMount: ->
    @refs.ceWrap.focus()

module.exports = ContenteditableTestHarness
