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

  # Iterates over found matches, highlights them
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
    cp = @editor.getCursorBufferPosition()
    @gotoNextMatch cp

  # Return next cursor position in the specified direction
  getCursorPosition: (dir) ->
    return null unless @editor
    pos = @editor.getCursorBufferPosition()
    if dir == 'next' then new Point pos.row, pos.column + 1 else new Point pos.row, pos.column - 1

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
  selectFollowingInHighlights: (dir, from) ->
    # cursor = @editor.getCursorBufferPosition()
    cursor = if from then from else @getCursorPosition dir
    return null unless cursor

    data = if dir == 'next' then @highlights else @highlights[..].reverse()

    for marker in data
      start = marker.getStartBufferPosition()

      if dir == 'next'
        return marker if (start.row == cursor.row and start.column >= cursor.column) or
          start.row > cursor.row
      else
        return marker if (start.row == cursor.row and start.column <= cursor.column) or
          start.row < cursor.row

    return null

  # Selects next match
  gotoNextMatch: (from = null) ->
    if @options.highlight_all
      # move to next match
      @currentMarker = @selectFollowingInHighlights 'next', from
      if !@currentMarker and @highlights[0]
        @currentMarker = @highlights[0]
      @editor.setCursorBufferPosition @currentMarker.getStartBufferPosition() if @currentMarker

    else
      # find next match
      startPosition = if from then from else @getCursorPosition 'next'
      range = new Range startPosition, @editor.getBuffer().getEndPosition()

      # try to
      matchFound = @selectFollowing 'next', range
      if !matchFound
        # no following match found - starting from top
        range = new Range (new Point 0, 0), @editor.getCursorBufferPosition()
        @selectFollowing 'next', range

    # add match selection
    if @currentMarker
      @updateDecorations()

  # Select previous match
  gotoPrevMatch: ->
    if @options.highlight_all
      # move to previous match
      @currentMarker = @selectFollowingInHighlights 'prev'
      if !@currentMarker and @highlights[@highlights.length - 1]
        @currentMarker = @highlights[@highlights.length - 1]
      @editor.setCursorBufferPosition @currentMarker.getStartBufferPosition() if @currentMarker

    else
      # find previous match
      # endPosition = (if @currentMarker then @currentMarker.getStartBufferPosition() else @editor.getCursorBufferPosition())
      endPosition = @editor.getCursorBufferPosition()
      range = new Range (new Point 0, 0), endPosition

      # try to
      matchFound = @selectFollowing 'prev', range
      if !matchFound
        # no following match found - starting from top
        range = new Range @editor.getCursorBufferPosition(), @editor.getBuffer().getEndPosition()
        @selectFollowing 'prev', range

    # add match selection
    if @currentMarker
      @updateDecorations()

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
      if @editor
        if accept
          @editor.setSelectedBufferRange @currentMarker.getBufferRange(), reversed: true if @currentMarker
        else
          sel = @editor.getLastSelection()
          sel.clear() if sel
          @editor.setCursorBufferPosition @currentMarker.getStartBufferPosition() if @currentMarker

      cursorPos = @currentMarker.getStartBufferPosition() if @currentMarker
      @unmatchAll()
      @editor.setCursorBufferPosition cursorPos if @currentMarker and @editor

    @query = ''
    @editor = null
