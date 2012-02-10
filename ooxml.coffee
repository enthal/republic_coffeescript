#! /usr/bin/env coffee

log = console.log

parser = require("sax").parser true

sax_reader = require("./sax_reader")

reader = sax_reader.attach parser,
  onopentag:  (node, push_delegate) ->
    #log reader.depth(), "OPEN ", node
    throw "Need: <office:document>" unless node.name is "office:document"

    push_delegate
      onopentag: (node, push_delegate) ->
        if node.name is "office:body"
          do_body push_delegate
        else
          push_delegate {}

do_body = (push_delegate) ->
  try fs.mkdirSync("OUT")
  f_text = fs.openSync("OUT/text.html",  "w+")
  f_note = fs.openSync("OUT/notes.html", "w+")

  make_body_delegate = (f) ->
    html_tags_by_name =
      "text:p":    "p"
      "text:span": "span"
      "text:h":    "h1"

    ontext:    (text) ->
      write_to f, text

    onopentag: (node, push_delegate) ->
      ln = html_tags_by_name[node.name]
      if ln
        space = if ln is "span" then "" else "\n"  # Only allow extra ws around block element tags, else browser shows it
        write_to f, "#{space}<#{ln}>"
      else switch node.name
        when "text:note"
          push_delegate make_note_delegate()
        when "text:note-ref"
          write_to f_note, "<A href='\##{node.attributes["text:ref-name"]}'>"
          push_delegate make_body_delegate(f_note)

    onclosetag: (name) ->
      ln = html_tags_by_name[name]
      if ln
        write_to f, "</#{ln}>"
      else switch name
        when "text:note-ref"
          write_to f_note, "</A>"

  make_note_delegate = ->
    ontext:    (text) ->
      text = text.trim()
      write_to f, text for f in [f_text, f_note]

    onopentag: (node, push_delegate) ->
      note_id = @base_node.attributes['text:id']
      switch node.name
        when "text:note-citation"
          write_to f_text, "<A href='notes.html\##{note_id}' name='#{note_id}'>"
          write_to f_note, "\n<div>\n<a href='text.html\##{note_id}' name='#{note_id}'><b>"
        when "text:note-body"
          push_delegate make_body_delegate(f_note)

    onclosetag: (name) ->
      switch name
        when "text:note-citation"
          write_to f_text, "</A>"
          write_to f_note, "</b></a>"
        when "text:note-body"
          write_to f_note, "\n</div>\n"

  push_delegate make_body_delegate(f_text)

local_name = (name) ->
  m = /.*:(.*)/.exec(name)
  m? and m[1] or name

write_to = (f, s) -> fs.writeSync f, s


fs = require "fs"
log process.argv
xml_str = fs.readFileSync(process.argv[2])
parser.write(xml_str.toString()).close()
