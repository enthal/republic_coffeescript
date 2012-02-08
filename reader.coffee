
make_reader = (parser, first_delegate) ->
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


log = console.log

sax = require "../../sax-js/lib/sax.js"
parser = sax.parser true
r = make_reader parser,
  onopentag:  (node) -> log r.depth(), "OPEN ", node
  onclosetag: (name) -> log r.depth(), "CLOSE", name
  ontext:     (text) -> log r.depth(), "TEXT:", text
parser.write('<xml>Hello, <who name="there">world</who>!</xml>').close()

r = make_reader parser,
  onopentag:  (node) ->
    log r.depth(), "OPEN ", node
    if node.name is "inner"
      onopentag:  (node) -> log "INNER!", node
      onclosetag: (name) -> log "INNER!", "CLOSE", name
      ontext:     (text) -> log "INNER!", text
  onclosetag: (name) -> log r.depth(), "CLOSE", name
  ontext:     (text) -> log r.depth(), "TEXT:", text
parser.write('<xml>Hello, <who name="there">what?<inner>¡olé!<bob>bro<sam/>yeah</bob>ok</inner>out!</who>!</xml>').close()

