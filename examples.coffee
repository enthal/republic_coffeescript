log = console.log

parser = require("sax").parser true

make_reader = require("./sax_reader").make_reader

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
