top.onload = ->
  show_export_date()

window.handle = -> console.log 'handle'

window.show_export_date = ->
  export_date_text = get_iframe_doc("text").getElementById("text-data").getAttribute("data-export-date")
  top.document.getElementById("date-display").innerHTML = export_date_text.match(/(.*)T/)[1] or export_date_text

get_iframe_doc = (iframe_id) ->
  iframe = top.document.getElementById(iframe_id)
  iframe.content_document or iframe.contentWindow.document

window.on_note_ref_click = (target, event) ->
  true
window.on_note_ref_mouseover = (target, event) ->
  get_note_div(target.name).style.backgroundColor = "#FFC"
window.on_note_ref_mouseout = (target, event) ->
  get_note_div(target.name).style.backgroundColor = null
get_note_div = (ref_name) ->
  get_iframe_doc("notes").getElementsByName("note-" + ref_name)[0]

window.on_note_ident_click = (target, event) ->
  true
window.on_note_ident_mouseover = (target, event) ->
  console.log top, top.document, document
window.on_note_ident_mouseout = (target, event) ->
