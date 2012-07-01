#! /usr/bin/env coffee

fs = require "fs"
log = console.log
parser = require("sax").parser true

sax_reader = require("./sax_reader")

font_families_by_style_name = {}
export_date = null

reader = sax_reader.attach parser,
  onopentag: (node, push_delegate) ->
    throw "Need: <office:document> not <#{node.name}>" unless node.name is "office:document"
    f_style = output_file "styles", "less"

    push_delegate
      onopentag: (node, push_delegate) ->
        switch node.name
          when "office:meta"
            do_office_meta push_delegate
          when "office:font-face-decls"
            do_font_face_decls push_delegate
          when "office:styles", "office:automatic-styles"
            do_styles f_style, push_delegate
          when "office:body"
            do_body push_delegate
          else
            push_delegate {}  # skip subtree

do_office_meta = (push_delegate) ->
  push_delegate
    onopentag: (node, push_delegate) ->
      if node.name is "dc:date"
        push_delegate
          ontext: (text) ->
            export_date = text

do_font_face_decls = (push_delegate) ->
  push_delegate
    onopentag: (node, push_delegate) ->
      if node.name is "style:font-face"
        nas = node.attributes
        font_families_by_style_name[nas["style:name"]] = nas["svg:font-family"]

do_styles = (f_style, push_delegate) ->
  push_delegate
    onopentag: (node, push_delegate) ->
      if node.name is "style:style"
        style_name = node.attributes["style:name"]
        push_delegate
          onenter: (node) ->
            f_style.write_line ".#{style_name} {"
            parent_style_name = node.attributes["style:parent-style-name"]
            f_style.write_line "  .#{parent_style_name};"  if parent_style_name
          onleave: ->
            f_style.write_line "}\n"
          onopentag: (node) ->
            for n,v of node.attributes
              m = n.match /^fo:(.*)/
              f_style.write_line "  #{m[1]}: #{v};"  if m
              font_family = font_families_by_style_name[v]
              f_style.write_line "  font-family: #{font_family};" if n is "style:font-name"

do_body = (push_delegate) ->
  f_text      = output_file "text"
  f_note      = output_file "notes"
  f_contents  = output_file "contents"
  f_bookmarks = output_file "bookmarks"

  make_body_delegate = (f) ->
    html_tags_by_name =
      "text:p":    "div"
      "text:h":    "div"
      "text:span": "span"
    header_i = 0

    collected_texts: []

    ontext: (text) ->
      f.write text
      @collected_texts.push text

    onopentag: (node, push_delegate) ->
      tag_name = html_tags_by_name[node.name]
      if tag_name
        css_classes = [node.attributes["text:style-name"]]
        if node.name is "text:h"
          header_i++
          header_name = "header_#{header_i}"
          css_level_class = "CONV-level-#{node.attributes["text:outline-level"]}"
          css_classes.push "CONV-header"
          css_classes.push css_level_class

          header_delegate = make_body_delegate f
          header_delegate.onleave = ->
            item = ""
            item += "<div"
            item += " class='CONV-content-tile #{css_level_class}'>"
            item += "<A href='text.html\##{header_name}' target='text'>"
            item += @collected_texts.join ''
            item += "</A></div>"
            f_contents.write_line item
          push_delegate header_delegate

        style_name = node.attributes["text:style-name"]
        tag = ""
        tag += "\n" unless tag_name is "span"  # Only allow extra ws around block element tags, else browser shows it
        tag += "<#{tag_name}"
        tag += " class='#{css_classes.join ' '}'" if css_classes.length
        tag += ">"
        f.write tag

        if node.name is "text:h"
          f.write "<A name='#{header_name}'>"

      else switch node.name
        when "text:note"
          push_delegate make_note_delegate()
        when "text:note-ref"
          f_note.write "<A href='\##{node.attributes["text:ref-name"]}' class='CONV-note-reference'>"
          push_delegate make_body_delegate(f_note)
        when "text:bookmark-start"
          bookmark_id = node.attributes["text:name"]
          bookmark_name = "bookmark_#{bookmark_id}"
          f_bookmarks.write "\n<div class='CONV-bookmark' name='#{bookmark_name}'><A href='text.html\##{bookmark_name}' target='text' class='CONV-bookmark-ref'>#{bookmark_id}</A></div>"
          f.write "<A name='#{bookmark_name}' class='CONV-bookmark-reference'></A>"

    onclosetag: (name) ->
      tag_name = html_tags_by_name[name]
      if tag_name
        if name is "text:h"
          f.write "</A>"
        f.write "</#{tag_name}>"
      else switch name
        when "text:note-ref"
          f_note.write "</A>"


  make_note_delegate = ->
    ontext: (text) ->
      text = text.trim()
      f.write text for f in [f_text, f_note]

    onopentag: (node, push_delegate) ->
      note_id = @base_node.attributes['text:id']
      switch node.name
        when "text:note-citation"
          f_text.write "<A href='notes.html\##{note_id}' target='notes' name='#{note_id}' class='CONV-note-reference'>"
          f_note.write "\n<div class='CONV-note' name='note-#{note_id}'>\n"
          f_note.write "<A href='text.html\##{note_id}' target='text' name='#{note_id}' class='CONV-note-identifier'>"
        when "text:note-body"
          push_delegate make_body_delegate(f_note)

    onclosetag: (name) ->
      switch name
        when "text:note-citation"
          f_text.write "</A>"
          f_note.write "</A>"
        when "text:note-body"
          f_note.write "\n</div>\n"

  do ->
    outer_body_delegate = make_body_delegate(f_text)

    outer_body_delegate.onenter = ->
      for f in [f_text, f_note, f_contents, f_bookmarks]
        f.write_line "<!DOCTYPE html>"
        f.write_line "<HTML>"
        f.write_line "<HEAD>"
        f.write_line '  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">'
        f.write_line '  <link rel="stylesheet/less" type="text/css" href="styles.less">'
        f.write_line '  <link rel="stylesheet/less" type="text/css" href="../custom.less">'
        f.write_line '  <script src="../ext/less/less-1.2.2.min.js" type="text/javascript"></script>'
        f.write_line '  <script src="../js.js" type="text/javascript"></script>'
        f.write_line "</HEAD>"
        f.write_line "<BODY name='#{f.name}'"
        for hook in ("onclick onmouseover onmouseout".split(' '))
          f.write_line "    #{hook}='return handle(event)'"
        f.write_line ">\n"
        f.write_line "<div id='text-data' data-export-date='#{export_date}'></div>" if f is f_text
        f.write_line "<DIV class='scroll-container' onscroll='return handle(event)'>"
        f.write_line "<DIV class='scroll-content'>"



    outer_body_delegate.onleave = ->
      for f in [f_text, f_note, f_contents, f_bookmarks]
        f.write_line "\n"
        f.write_line "</DIV>"
        f.write_line "</DIV>"
        f.write_line "</BODY>"
        f.write_line "</HTML>"

    push_delegate outer_body_delegate


local_name = (name) ->
  m = /.*:(.*)/.exec(name)
  m? and m[1] or name

output_file = (name, extension='html') ->
  out_path = "public/OUT/"
  try fs.mkdirSync out_path
  f = fs.openSync "#{out_path}/#{name}.#{extension}", "w+"

  name       : name
  write      : (s) -> fs.writeSync f, s
  write_line : (s) -> fs.writeSync f, s + "\n"

exports.run = run = (input_filename) ->
  parser.write(fs.readFileSync input_filename, 'utf-8').close()

unless module.parent
  log process.argv
  run process.argv[2]
