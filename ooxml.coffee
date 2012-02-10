#! /usr/bin/env coffee

fs = require "fs"
log = console.log
parser = require("sax").parser true

sax_reader = require("./sax_reader")

try fs.mkdirSync("OUT")
f_text = fs.openSync("OUT/text.html",  "w+")
f_note = fs.openSync("OUT/notes.html", "w+")

reader = sax_reader.attach parser,
  onopentag:  (node, push_delegate) ->
    throw "Need: <office:document> not <#{node.name}>" unless node.name is "office:document"

    for f in [f_text, f_note]
      write_line_to f, "<HTML>"
      write_line_to f, "<HEAD>"
      write_line_to f, '  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">'
      write_line_to f, '  <link rel="stylesheet" type="text/css" href="css.css">'
      write_line_to f, "</HEAD>"
      write_line_to f, "<BODY>"

    push_delegate
      onopentag: (node, push_delegate) ->
        switch node.name
          when "office:styles"
            do_styles push_delegate
          when "office:body"
            do_body push_delegate
          else
            push_delegate {}  # skip subtree

  onclosetag: (name) ->
    throw "Need: </office:document> not <#{name}>" unless name is "office:document"

    for f in [f_text, f_note]
      write_line_to f, "\n"
      write_line_to f, "</BODY>"
      write_line_to f, "</HTML>"

do_styles = (push_delegate) ->
  try fs.mkdirSync("OUT")
  f = fs.openSync("OUT/css.css", "w+")
  write_to f, ".Stephanus_20_Number { color: blue; }"

do_body = (push_delegate) ->
  make_body_delegate = (f) ->
    html_tags_by_name =
      "text:p":    "p"
      "text:span": "span"
      "text:h":    "h1"

    ontext:    (text) ->
      write_to f, text

    onopentag: (node, push_delegate) ->
      tag_name = html_tags_by_name[node.name]
      if tag_name
        style_name = node.attributes["text:style-name"]
        tag = ""
        tag += "\n" unless tag_name is "span"  # Only allow extra ws around block element tags, else browser shows it
        tag += "<#{tag_name}"
        tag += " class='#{style_name}'" if style_name
        tag += ">"
        write_to f, tag
      else switch node.name
        when "text:note"
          push_delegate make_note_delegate()
        when "text:note-ref"
          write_to f_note, "<A href='\##{node.attributes["text:ref-name"]}'>"
          push_delegate make_body_delegate(f_note)

    onclosetag: (name) ->
      tag_name = html_tags_by_name[name]
      if tag_name
        write_to f, "</#{tag_name}>"
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
write_line_to = (f, s) -> write_to f, s + "\n"

log process.argv
xml_str = fs.readFileSync(process.argv[2])
parser.write(xml_str.toString()).close()
