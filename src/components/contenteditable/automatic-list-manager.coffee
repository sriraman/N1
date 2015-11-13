{DOMUtils} = require 'nylas-exports'
ContenteditablePlugin = require './contenteditable-plugin'

class AutomaticListManager extends ContenteditablePlugin
  @onInput: (event, editableNode, selection) ->
    return unless selection?.anchorNode
    return if not selection.isCollapsed

    if @ignoreAutomaticListCreation
      @ignoreAutomaticListCreation = false
      return
    # if innerStateProxy.get("ignoreAutomaticListCreation")
    #   innerStateProxy.set(ignoreAutomaticListCreation: false)
    #   return

    text = selection.anchorNode.textContent
    if (/^\d\.\s$/).test text
      @originalInput = text
      document.execCommand("insertOrderedList")
    else if (/^[*-]\s$/).test text
      @originalInput = text
      document.execCommand("insertUnorderedList")
      selection.anchorNode.parentElement.innerHTML = ""

  @onKeyDown: (event, editableNode, selection) ->
    return unless event.key is "Backspace"

    if DOMUtils.atStartOfList()
      li = DOMUtils.closestAtCursor("li")
      list = DOMUtils.closestAtCursor("ul, ol")
      return unless li and list
      event.preventDefault()

      if @originalInput
        # DOMUtils.Mutating.replaceFirstListItem(li, originalText)
        document.execCommand("outdent")
        document.execCommand("insertHTML", @originalInput)
        @originalInput = null
      else
        document.execCommand("outdent")

      # if list.querySelectorAll('li')?[0] is li # We're in first li
      #   hasContent = (li.textContent ? "").trim().length > 0
      #   if innerStateProxy.get("autoCreatedListFromText")
      #     innerStateProxy.set ignoreAutomaticListCreation: true
      #     originalText = innerStateProxy.get("autoCreatedListFromText")
      #     DOMUtils.Mutating.replaceFirstListItem(li, originalText)
      #   else if hasContent
      #     innerStateProxy.set ignoreAutomaticListCreation: true
      #     DOMUtils.Mutating.replaceFirstListItem(li, li.innerHTML)
      #   else
      #     DOMUtils.Mutating.replaceFirstListItem(li, "")
      # else

module.exports = AutomaticListManager
