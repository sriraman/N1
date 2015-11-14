_str = require 'underscore.string'
{DOMUtils} = require 'nylas-exports'
ContenteditablePlugin = require './contenteditable-plugin'

class AutomaticListManager extends ContenteditablePlugin
  @onKeyDown: (event, editableNode, selection) ->
    if event.key is "Backspace" and DOMUtils.atStartOfList()
      @outdentListItem(selection)
    else if event.key is " " and @hasListStartSignature(editableNode, selection)
      @createList(event, selection)

  @bulletRegex: -> /^[*-]/

  @numberedRegex: -> /^\d\./

  @hasListStartSignature: (editableNode, selection) ->
    return false unless selection?.anchorNode
    return false if not selection.isCollapsed

    text = selection.anchorNode.textContent
    return @numberedRegex().test(text) or @bulletRegex().test(text)

  @createList: (event, selection) ->
    @saveOriginalInput(selection)
    text = selection.anchorNode?.textContent

    if @numberedRegex().test(text)
      document.execCommand("insertOrderedList")
      @removeListStarter(@numberedRegex(), selection)
    else if @bulletRegex().test(text)
      document.execCommand("insertUnorderedList")
      @removeListStarter(@bulletRegex(), selection)
    else
      return
    event.preventDefault()

  @removeListStarter: (starterRegex, selection) ->
    el = DOMUtils.closest(selection.anchorNode, "li")
    textContent = el.textContent.replace(starterRegex, "")
    if textContent.trim().length is 0
      el.innerHTML = "<br>"
    else
      textNode = DOMUtils.findFirstTextNode(el)
      textNode.textContent = textNode.textContent.replace(starterRegex, "")

  @saveOriginalInput: (selection) ->
    node = selection.anchorNode
    return unless node
    if node.nodeType is Node.ELEMENT_NODE
      node = DOMUtils.findFirstTextNode(node)

    if (index = node.textContent.search(@numberedRegex())) > -1
      index += 2 # digit plus dot
    else if (index = node.textContent.search(@bulletRegex())) > -1
      index += 1 # dash or star

    if index > -1
      @originalInput = _str.splice(node.textContent, index, 0, " ")

  # From a newly-created list
  # Outdent returns to a <div><br/></div> structure
  # I need to turn into <div>-&nbsp;</div>
  #
  # From a list with content
  # Outent returns to <div>sometext</div>
  # We need to turn that into <div>-&nbsp;sometext</div>
  @restoreOriginalInput: (selection) ->
    node = selection.anchorNode
    return unless node
    if node.nodeType is Node.TEXT_NODE
      node.textContent = @originalInput
    else if node.nodeType is Node.ELEMENT_NODE
      textNode = DOMUtils.findFirstTextNode(node)
      if not textNode
        node.innerHTML = @originalInput.replace(" ", "&nbsp;")
      else
        textNode.textContent = @originalInput

    # if @numberedRegex().test(@originalInput) or @bulletRegex().test(@originalInput)
      # DOMUtils.Mutating.moveSelectionToEnd(selection)

    @originalInput = null

  @outdentListItem: (selection) ->
    li = DOMUtils.closestAtCursor("li")
    list = DOMUtils.closestAtCursor("ul, ol")
    return unless li and list
    event.preventDefault()

    if @originalInput
      document.execCommand("outdent")
      @restoreOriginalInput(selection)
    else
      document.execCommand("outdent")

module.exports = AutomaticListManager
