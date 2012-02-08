#! /usr/bin/env coffee

log = console.log

parser = require("sax").parser true

sax_reader = require("./sax_reader")

reader = sax_reader.attach parser,
  onopentag:  (node, push_delegate) ->
    #log reader.depth(), "OPEN ", node
    throw "WTF is this?" unless node.name is "office:document"

    push_delegate
      onopentag: (node, push_delegate) ->
        if node.name is "office:body"
          try fs.mkdirSync("OUT")
          f_text = fs.openSync("OUT/text.html",  "w+")
          f_note = fs.openSync("OUT/notes.html", "w+")

          push_delegate
            onopentag: (node, push_delegate) ->
              ln = local_name(node.name)
              fs.writeSync f_text, "\n<#{ln}>" if ln in ["p", "span"]
            ontext:    (text) -> fs.writeSync f_text, text
            onclosetag: (name) ->
              ln = local_name(name)
              fs.writeSync f_text, "</#{ln}>" if ln in ["p", "span"]
        else
          push_delegate {}

local_name = (name) ->
  m = /.*:(.*)/.exec(name)
  m? and m[1] or name


fs = require "fs"
log process.argv
xml_str = fs.readFileSync(process.argv[2])
parser.write(xml_str.toString()).close()
