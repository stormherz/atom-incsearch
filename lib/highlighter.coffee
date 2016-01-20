{Point, Range} = require 'atom'

module.exports =
class Highlighter
  constructor: (options) ->
    @editor = null
    @query = ''
    @highlights = []
    @currentMarker = null

    @options = options

  # Update highlighter rendering
  update: () ->
    @match @query

  # Iterates over found matches, highlights them, moves cursor to closest match
  iterateMatches: (match) =>
    marker = @editor.markBufferRange match.range, (
      persistent: false,
      invalidate: 'never'
    )

    @editor.decorateMarker marker, (
      type: 'highlight',
      class: 'incsearch-highlight',
    )

    @highlights.push marker

  # Creates regular expression object with options, based on highlighter configuration
  createRegex: (query) ->
    # escape regexp special symbols if searching plain text
    if !@options.regex
      query = query.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")

    # create appropriate regexp object
    if @options.highlight_all
      if @options.case_sensitive then new RegExp(query, 'g') else new RegExp(query, 'ig')
    else
      if @options.case_sensitive then new RegExp(query) else new RegExp(query, 'i')

  # Add highlight for specified query
  match: (query) ->
    return if !@editor or !query

    @query = query

    # clear previous marks
    @unmatchAll()

    # iterate over matches
    if @options.highlight_all
      @editor.scan @createRegex(query), (match) =>
        @iterateMatches(match)
    else
      startPosition = (if @currentMarker then @currentMarker.getEndBufferPosition() else @editor.getCursorBufferPosition())
      range = new Range startPosition, @editor.getBuffer().getEndPosition()
      @editor.scanInBufferRange @createRegex(query), range, (match) =>
        @iterateMatches(match)

    # move cursor to closest match
    @gotoNextMatch()

  # Selects single following match in next and previous directions
  selectFollowing: (dir, range) ->
    matchFound = false

    iterator = (match) =>
      matchFound = true
      @unmatchAll()
      @iterateMatches match
      @currentMarker = (if @highlights[0] then @highlights[0] else null)
      @editor.setCursorBufferPosition @currentMarker.getStartBufferPosition() if @currentMarker

    if dir == 'next'
      @editor.scanInBufferRange @createRegex(@query), range, (match) -> iterator(match)
    else
      @editor.backwardsScanInBufferRange @createRegex(@query), range, (match) -> iterator(match)

    matchFound

  # Finds next match in hidhlights
  selectFollowingInHighlights: (dir) ->
    cursor = @editor.getCursorBufferPosition()
    data = if dir == 'next' then @highlights else @highlights.clone().reverse()

    for marker in data
      start = marker.getEndBufferPosition()

      if dir == 'next'
        return marker if (start.row == cursor.row and start.column >= cursor.column) or
          start.row > cursor.row
      else
        return marker if (start.row == cursor.row and start.column <= cursor.column) or
          start.row < cursor.row

    return null

  # Selects next match
  gotoNextMatch: ->
    if @options.highlight_all
      # move to next match
      if @currentMarker
        index = @highlights.indexOf @currentMarker
        return if index == -1

        marker = (if @highlights[index + 1] then @highlights[index + 1] else @highlights[0])
        @currentMarker = marker
      else
        @currentMarker = @selectFollowingInHighlights 'next'
        if !@currentMarker and @highlights[0]
          @currentMarker = @highlights[0]

      @editor.setCursorBufferPosition @currentMarker.getStartBufferPosition() if @currentMarker

    else
      # find next match
      startPosition = (if @currentMarker then @currentMarker.getEndBufferPosition() else @editor.getCursorBufferPosition())
      range = new Range startPosition, @editor.getBuffer().getEndPosition()

      # try to
      matchFound = @selectFollowing('next', range)
      if !matchFound
        # no following match found - starting from top
        range = new Range (new Point 0, 0), @editor.getCursorBufferPosition()
        @selectFollowing('next', range)

    # add match selection
    if @currentMarker
      @updateDecorations()
      @editor.setSelectedBufferRange @currentMarker.getBufferRange(), reversed: true

  # Select previous match
  gotoPrevMatch: ->
    if @options.highlight_all
      # move to previous match
      if @currentMarker
        index = @highlights.indexOf @currentMarker
        return if index == -1

        marker = if @highlights[index - 1] then @highlights[index - 1] else @highlights[@highlights.length - 1]
        @currentMarker = marker
      else
        @currentMarker = @selectFollowingInHighlights 'prev'
        if !@currentMarker and @highlights[@highlights.length - 1]
          @currentMarker = @highlights[@highlights.length - 1]

      @editor.setCursorBufferPosition @currentMarker.getStartBufferPosition() if @currentMarker
    else
      # find previous match
      endPosition = (if @currentMarker then @currentMarker.getStartBufferPosition() else @editor.getCursorBufferPosition())
      range = new Range (new Point 0, 0), endPosition

      # try to
      matchFound = @selectFollowing('prev', range)
      if !matchFound
        # no following match found - starting from top
        range = new Range @editor.getCursorBufferPosition(), @editor.getBuffer().getEndPosition()
        @selectFollowing('prev', range)

    # add match selection
    if @currentMarker
      @updateDecorations()
      @editor.setSelectedBufferRange @currentMarker.getBufferRange(), reversed: true

  # Update matched marker decorations
  updateDecorations: ->
    return if !@currentMarker

    for decoration in (@editor.getDecorations type: 'highlight')
      currentClass = decoration.getProperties()?.class
      continue if currentClass != 'incsearch-current' and currentClass != 'incsearch-highlight'

      cls = (if decoration.getMarker().isEqual @currentMarker then 'incsearch-current' else 'incsearch-highlight')
      decoration.setProperties type: 'highlight', class: cls

  # Clear all active highlights
  unmatchAll: ->
    marker.destroy() for marker in @highlights
    @currentMarker = null
    @highlights = []

  # Activate highlighter, bind it to editor
  activate: (editor) ->
    @editor = editor

  # Deactivate highlighter, unbind from editor
  deactivate: (accept, destroyed) ->
    if !destroyed
      # remove selection if search was closed without accepting
      if !accept and @editor
        sel = @editor.getLastSelection()
        sel.clear() if sel
        @editor.setCursorBufferPosition @currentMarker.getStartBufferPosition() if @currentMarker

      cursorPos = @currentMarker.getStartBufferPosition() if @currentMarker
      @unmatchAll()
      @editor.setCursorBufferPosition cursorPos if @currentMarker and @editor

    @query = ''
    @editor = null
