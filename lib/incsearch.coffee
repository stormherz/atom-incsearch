IncsearchView = require './incsearch-view'
Highlighter = require './highlighter'
{CompositeDisposable} = require 'atom'

module.exports = Incsearch =
  config:
    minimalSearchLength:
      title: 'Minimal search length'
      description: 'Number of typed characters to start searching'
      type: 'integer'
      default: 2
      minimum: 1

  view: null
  panel: null
  subscriptions: null

  loaded: false
  options: null
  highlighter: null

  # Highlights search query
  highlightQuery: (query) ->
    if query.length <= (atom.config.get('incsearch.minimalSearchLength') - 1)
      @highlighter.unmatchAll()
      return

    # highlight matches
    @highlighter.match(query)

  changeOption: (option, value) ->
    @options[option] = value
    @highlighter.options = @options
    @highlighter.update()

  load: ->
    # view and events handling
    @view = new IncsearchView
    @view.onClose => @hide()
    @view.onAccept => @hide(true)
    @view.onOptionChange (e) => @changeOption(e.option, e.value)
    @view.onInputChange (query) => @highlightQuery(query)
    @view.onNextMatch =>
      return unless @panel and @panel.visible
      @highlighter.gotoNextMatch()
    @view.onPrevMatch =>
      return unless @panel and @panel.visible
      @highlighter.gotoPrevMatch()

    # highlighter configuration
    @highlighter = new Highlighter @options
    @highlighter.onMatchesChange (matches) =>
      @view.updateMatches matches

    # add view
    @panel = atom.workspace.addBottomPanel(item: @view.getElement(), visible: false)

    # activate previous state
    highlightToggler = => @view.btnHighlight.click()
    regexToggler = => @view.btnRegex.click()
    caseToggler = => @view.btnCase.click()

    highlightToggler() if @options.highlight_all
    regexToggler() if @options.regex
    caseToggler() if @options.case_sensitive

    # manageing subscriptions
    @subscriptions.add atom.commands.add 'atom-workspace', 'core:cancel': => @hide()
    @subscriptions.add atom.commands.add 'atom-workspace', 'incsearch-global:goto:next-match': =>
      return unless @panel and @panel.visible
      @highlighter.gotoNextMatch()
    @subscriptions.add atom.commands.add 'atom-workspace', 'incsearch-global:goto:prev-match': =>
      return unless @panel and @panel.visible
      @highlighter.gotoPrevMatch()
    @subscriptions.add atom.commands.add '.incsearch', 'incsearch:toggle-option:highlight_all': highlightToggler
    @subscriptions.add atom.commands.add '.incsearch', 'incsearch:toggle-option:regex': regexToggler
    @subscriptions.add atom.commands.add '.incsearch', 'incsearch:toggle-option:case_sensitive': caseToggler
    @subscriptions.add atom.commands.add '.incsearch', 'incsearch:goto:next-match': =>
      return unless @panel and @panel.visible
      @highlighter.gotoNextMatch()
    @subscriptions.add atom.commands.add '.incsearch', 'incsearch:goto:prev-match': =>
      return unless @panel and @panel.visible
      @highlighter.gotoPrevMatch()

    # set loaded state
    @loaded = true

  activate: (state) ->
    @options =
      highlight_all: false
      regex: false
      case_sensitive: false

    if state
      @options = state.options if state.options

    # deserialising
    @options = state.options if state.options

    # managing subscriptions
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'incsearch:toggle': =>
      # deferred loading
      @load() if !@loaded
      if @panel and @panel.visible
        @highlighter.gotoNextMatch()
      else
        @show()

  deactivate: ->
    if @loaded
      @highlighter.deactivate()
      @panel.destroy()
      @view.destroy()

    @subscriptions.dispose()

  serialize: ->
    options: @options

  hide: (accept, destroyed) ->
    return if !@panel.isVisible()

    @highlighter.deactivate accept, destroyed
    @panel.hide()
    @view.input.val ''
    @view.updateMatches()

    atom.workspace.getActivePane().activate()

  show: ->
    if @panel.isVisible()
      @view.input.focus()
      return

    # handle editor events
    editor = atom.workspace.getActiveTextEditor()
    return if !editor
    editor.onDidDestroy => @hide false, true

    # activate highlighter
    @highlighter.activate editor

    @panel.show()

    selection = editor.getLastSelection()
    @view.input.val selection.getText()
    @view.input.focus()
