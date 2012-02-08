
exports.make_reader = (parser, first_delegate) ->
  delegate = null
  depth = 0

  push_delegate = (new_delegate) ->
    new_delegate.last_delegate = delegate
    delegate = new_delegate
    delegate.start_depth = depth

  push_delegate first_delegate

  parser.onopentag = (node) ->
    new_delegate = delegate.onopentag(node) if delegate and delegate.onopentag?
    push_delegate new_delegate if new_delegate?
    depth++
  parser.ontext = (text) ->
    delegate.ontext(text) if delegate? and delegate.ontext?
  parser.onclosetag = (node) ->
    depth--
    delegate = delegate.last_delegate if depth <= delegate.start_depth
    delegate.onclosetag(node) if delegate? and delegate.onclosetag?

  parser: parser
  depth: () -> depth

