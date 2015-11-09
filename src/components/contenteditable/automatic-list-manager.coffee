ContenteditablePlugin = require './contenteditable-plugin'

class AutomaticListManager extends ContenteditablePlugin
  @onInput: (event, editableNode, selection, innerStateProxy) ->
    return unless selection?.anchorNode
    return if selection.isCollapsed

    if innerStateProxy.get("ignoreAutomaticListCreation")
      innerStateProxy.set(ignoreAutomaticListCreation: false)
      return

    text = selection.anchorNode.textContent
    if (/^\d\.\s$/).test text
      innerStateProxy.set autoCreatedListFromText: text
      document.execCommand("insertOrderedList")
    else if (/^[*-]\s$/).test text
      innerStateProxy.set autoCreatedListFromText: text
      document.execCommand("insertUnorderedList")
      selection.anchorNode.parentElement.innerHTML = ""

  @onKeyDown: (event, editableNode, selection, innerStateProxy) ->
    return unless event.key is "Backspace"

    # Due to a bug in Chrome's contenteditable implementation, the
    # standard document.execCommand('outdent') doesn't work for the
    # first item in lists. As a result, we need to detect if we're
    # trying to outdent the first item in a list.
    if DOMUtils.atStartOfList()
      li = DOMUtils.closestAtCursor("li")
      list = DOMUtils.closestAtCursor("ul, ol")
      return unless li and list
      event.preventDefault()
      if list.querySelectorAll('li')?[0] is li # We're in first li
        hasContent = (li.textContent ? "").trim().length > 0
        if innerStateProxy.get("autoCreatedListFromText")
          innerStateProxy.set ignoreAutomaticListCreation: true
          originalText = innerStateProxy.get("autoCreatedListFromText")
          DOMUtils.Mutating.replaceFirstListItem(li, originalText)
        else if hasContent
          innerStateProxy.set ignoreAutomaticListCreation: true
          DOMUtils.Mutating.replaceFirstListItem(li, li.innerHTML)
        else
          DOMUtils.Mutating.replaceFirstListItem(li, "")
      else
        document.execCommand("outdent")


module.exports = AutomaticListManager
