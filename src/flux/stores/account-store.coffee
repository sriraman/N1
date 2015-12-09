Actions = require '../actions'
Account = require '../models/account'
Utils = require '../models/utils'
MenuHelpers = require '../../menu-helpers'
DatabaseStore = require './database-store'
_ = require 'underscore'

{Listener, Publisher} = require '../modules/reflux-coffee'
CoffeeHelpers = require '../coffee-helpers'

saveObjectsKey = "nylas.accounts"
saveTokensKey = "nylas.accountTokens"
saveIndexKey = "nylas.currentAccountIndex"

###
Public: The AccountStore listens to changes to the available accounts in
the database and exposes the currently active Account via {::current}

Section: Stores
###
class AccountStore
  @include: CoffeeHelpers.includeModule

  @include Publisher
  @include Listener

  constructor: ->
    @_load()
    @listenTo Actions.selectAccountId, @onSelectAccountId
    NylasEnv.config.observe saveTokensKey, (updatedTokens) =>
      return if _.isEqual(updatedTokens, @_tokens)
      newAccountIds = _.keys(_.omit(updatedTokens, _.keys(@_tokens)))
      @_load()
      if newAccountIds.length > 0
        Actions.selectAccountId(newAccountIds[0])

    @_setupFastAccountCommands()

  _setupFastAccountCommands: ->
    commands = {}
    [0..8].forEach (index) =>
      key = "application:select-account-#{index}"
      commands[key] = _.partial(@_selectAccountByIndex, index)
    NylasEnv.commands.add('body', commands)

  _setupFastAccountMenu: ->
    windowMenu = _.find NylasEnv.menu.template, ({label}) -> MenuHelpers.normalizeLabel(label) is 'Window'
    return unless windowMenu
    submenu = _.reject windowMenu.submenu, (item) -> item.account
    return unless submenu
    idx = _.findIndex submenu, ({type}) -> type is 'separator'
    return unless idx > 0

    accountMenuItems = @items().map (item, idx) =>
      {
        label: item.emailAddress,
        command: "application:select-account-#{idx}",
        account: true
      }

    submenu.splice(idx + 1, 0, accountMenuItems...)
    windowMenu.submenu = submenu
    NylasEnv.menu.update()

  _selectAccountByIndex: (index) =>
    require('electron').ipcRenderer.send('command', 'application:show-main-window')
    index = Math.min(@_accounts.length - 1, Math.max(0, index))
    Actions.selectAccountId(@_accounts[index].id)

  _load: =>
    @_accounts = []
    for json in NylasEnv.config.get(saveObjectsKey) || []
      @_accounts.push((new Account).fromJSON(json))

    index = NylasEnv.config.get(saveIndexKey) || 0
    @_index = Math.min(@_accounts.length - 1, Math.max(0, index))

    @_tokens = NylasEnv.config.get(saveTokensKey) || {}
    @_setupFastAccountMenu()
    @trigger()

  _save: =>
    NylasEnv.config.set(saveObjectsKey, @_accounts)
    NylasEnv.config.set(saveIndexKey, @_index)
    NylasEnv.config.set(saveTokensKey, @_tokens)
    NylasEnv.config.save()

  # Inbound Events

  onSelectAccountId: (id) =>
    idx = _.findIndex @_accounts, (a) -> a.id is id
    return if idx is -1 or @_index is idx
    NylasEnv.config.set(saveIndexKey, idx)
    @_index = idx
    @trigger()

  removeAccountId: (id) =>
    idx = _.findIndex @_accounts, (a) -> a.id is id
    return if idx is -1

    delete @_tokens[id]
    @_accounts.splice(idx, 1)
    @_save()

    if @_accounts.length is 0
      ipc = require('electron').ipcRenderer
      ipc.send('command', 'application:reset-config-and-relaunch')
    else
      if @_index is idx
        Actions.selectAccountId(@_accounts[0].id)
      @trigger()

  addAccountFromJSON: (json) =>
    if not json.email_address or not json.provider
      console.error("Returned account data is invalid", json)
      console.log JSON.stringify(json)
      throw new Error("Returned account data is invalid")
    return if @_tokens[json.id]
    @_tokens[json.id] = json.auth_token
    @_accounts.push((new Account).fromJSON(json))
    @_save()
    @onSelectAccountId(json.id)

  # Exposed Data

  # Public: Returns an {Array} of {Account} objects
  items: =>
    @_accounts

  # Public: Returns the {Account} for the given email address, or null.
  itemWithEmailAddress: (email) =>
    _.find @_accounts, (account) ->
      Utils.emailIsEquivalent(email, account.emailAddress)

  # Public: Returns the currently active {Account}.
  current: =>
    @_accounts[@_index] || null

  # Private: This method is going away soon, do not rely on it.
  #
  tokenForAccountId: (id) =>
    @_tokens[id]

  # Private: Load fake data from a directory for taking nice screenshots
  #
  _importFakeData: (dir) =>
    fs = require 'fs-plus'
    path = require 'path'
    DatabaseStore = require './database-store'
    Message = require '../models/message'
    Account = require '../models/account'
    Thread = require '../models/thread'
    Label = require '../models/label'

    labels = {}
    threads = []
    messages = []

    account = @itemWithEmailAddress('nora@nylas.com')
    unless account
      account = new Account()
      account.serverId = account.clientId
      account.emailAddress = "nora@nylas.com"
      account.organizationUnit = 'label'
      account.name = "Nora"
      account.provider = "gmail"
      @_accounts.push(account)
      @_tokens[account.id] = 'nope'

    filenames = fs.readdirSync(path.join(dir, 'threads'))
    for filename in filenames
      threadJSON = fs.readFileSync(path.join(dir, 'threads', filename))
      threadMessages = JSON.parse(threadJSON).map (j) -> (new Message).fromJSON(j)
      threadLabels = []
      threadParticipants = []
      threadAttachment = false
      threadUnread = false

      for m in threadMessages
        m.accountId = account.id
        for l in m.labels
          l.accountId = account.id
          unless l.id in labels
            labels[l.id] = l
        threadParticipants = threadParticipants.concat(m.participants())
        threadLabels = threadLabels.concat(m.labels)
        threadAttachment ||= m.files.length > 0
        threadUnread ||= m.unread

      threadParticipants = _.uniq threadParticipants, (p) -> p.email
      threadLabels = _.uniq threadLabels, (l) -> l.id

      lastMsg = _.last(threadMessages)
      thread = new Thread(
        accountId: account.id
        serverId: lastMsg.threadId
        clientId: lastMsg.threadId
        subject: lastMsg.subject
        lastMessageReceivedTimestamp: lastMsg.date
        hasAttachment: threadAttachment
        labels: threadLabels
        participants: threadParticipants
        unread: threadUnread
        snippet: lastMsg.snippet
        starred: lastMsg.starred
      )
      messages = messages.concat(threadMessages)
      threads.push(thread)

    downloadsDir = path.join(dir, 'downloads')
    for filename in fs.readdirSync(downloadsDir)
      fs.copySync(path.join(downloadsDir, filename), path.join(NylasEnv.getConfigDirPath(), 'downloads', filename))

    Promise.all([
      DatabaseStore.persistModel(account),
      DatabaseStore.persistModels(_.values(labels)),
      DatabaseStore.persistModels(messages),
      DatabaseStore.persistModels(threads)
    ]).then =>
      Actions.selectAccountId account.id

module.exports = new AccountStore()
