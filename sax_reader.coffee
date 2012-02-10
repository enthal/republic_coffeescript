
exports.attach = (parser, first_delegate) ->
  delegate = null
  depth = 0

  push_delegate = (new_delegate, base_node) ->
    new_delegate.last_delegate = delegate
    new_delegate.base_node = base_node
    delegate = new_delegate
    delegate.start_depth = depth
    new_delegate.onenter(base_node) if new_delegate.onenter

  push_delegate first_delegate

  parser.onopentag = (node) ->
    new_delegate = null
    delegate.onopentag(node, ((d) -> new_delegate = d)) if delegate and delegate.onopentag?
    push_delegate new_delegate, node if new_delegate?
    depth++
  parser.ontext = (text) ->
    delegate.ontext(text) if delegate? and delegate.ontext? and not /^\n *$/.test(text)
  parser.onclosetag = (name) ->
    depth--
    if depth <= delegate.start_depth
      delegate.onleave(name) if delegate.onleave
      delegate = delegate.last_delegate 
    delegate.onclosetag(name) if delegate? and delegate.onclosetag?

  parser: parser
  depth: () -> depth

