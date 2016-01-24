IncsearchView = require '../lib/incsearch-view'
$ = require 'jquery'

describe 'IncsearchView', ->
  beforeEach ->
    @view = new IncsearchView

    @callbacks =
      onClose: ->
      onAccept: ->
      onOptionChange: ->
      onNextMatch: ->
      onPrevMatch: ->

    spyOn @callbacks, handler for handler, _ of @callbacks

  it 'created', ->
    expect(@view.container).toBeDefined()

  it 'handles callbacks', ->
    @view.onClose @callbacks.onClose
    @view.onAccept @callbacks.onAccept
    @view.onOptionChange @callbacks.onOptionChange
    @view.onNextMatch @callbacks.onNextMatch
    @view.onPrevMatch @callbacks.onPrevMatch

    # close callback
    event = $.Event 'keydown'
    event.keyCode = 27
    @view.input.trigger event
    expect(@callbacks.onClose).toHaveBeenCalled()

    # accept callback
    event = $.Event 'keydown'
    event.keyCode = 13
    @view.input.trigger event
    expect(@callbacks.onAccept).toHaveBeenCalled()

    # option change callback
    @view.btnHighlight.click()
    calls = @callbacks.onOptionChange.calls
    expect(calls.length).toBe 1
    expect(calls[0].args.length).toBe 1
    expect(calls[0].args[0].option).toBe 'highlight_all'
    expect(calls[0].args[0].value).toBe true

    # next/prev match callback
    event = $.Event 'keydown'
    event.keyCode = 40
    event.altKey = true
    @view.input.trigger event
    expect(@callbacks.onNextMatch).toHaveBeenCalled()
    event = $.Event 'keydown'
    event.keyCode = 38
    event.altKey = true
    @view.input.trigger event
    expect(@callbacks.onPrevMatch).toHaveBeenCalled()



