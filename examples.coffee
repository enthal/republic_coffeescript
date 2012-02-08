log = console.log

parser = require("sax").parser true

sax_reader = require("./sax_reader")

r = sax_reader.attach parser,
  onopentag:  (node) -> log r.depth(), "OPEN ", node
  onclosetag: (name) -> log r.depth(), "CLOSE", name
  ontext:     (text) -> log r.depth(), "TEXT:", text
parser.write('<xml>Hello, <who name="there">world</who>!</xml>').close()

r = sax_reader.attach parser,
  onopentag:  (node, push_delegate) ->
    log r.depth(), "OPEN ", node
    if node.name is "inner"
      push_delegate
        onopentag:  (node) -> log "INNER!", node
        onclosetag: (name) -> log "INNER!", "CLOSE", name
        ontext:     (text) -> log "INNER!", text
  onclosetag: (name) -> log r.depth(), "CLOSE", name
  ontext:     (text) -> log r.depth(), "TEXT:", text
parser.write('<xml>Hello, <who name="there">what?<inner>¡olé!<bob>bro<sam/>yeah</bob>ok</inner>out!</who>!</xml>').close()
