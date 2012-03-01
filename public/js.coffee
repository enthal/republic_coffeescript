top.onload = ->
  show_export_date()

window.show_export_date = ->
  export_date_text = get_iframe_doc("text").getElementById("text-data").getAttribute("data-export-date")
  top.document.getElementById("date-display").innerHTML = export_date_text.match(/(.*)T/)[1] or export_date_text

window.handle = (event) ->
  target = event.target || event.srcElement || event.toElement
  #console.log("***** handle:", target.className, event.type)
  #console.log(event)

  controller =
    'CONV-note-reference':
      click: ->
        get_note_div(target.name).scrollIntoView(true)
        false
      mouseover: (target, event) ->
        get_note_div(target.name).style.backgroundColor = "#FFC"
      mouseout:  (target, event) ->
        get_note_div(target.name).style.backgroundColor = null
    'CONV-note-identifier':
      mouseover: (target, event) ->
        console.log top, top.document, document

  for css_class in target.classList
    action = try controller[css_class][event.type]
    if action
      console.log "ACTION: #{css_class} : #{event.type}"
      return action target, event

  true

get_iframe_doc = (iframe_id) ->
  iframe = top.document.getElementById(iframe_id)
  iframe.content_document or iframe.contentWindow.document

get_note_div = (ref_name) ->
  get_iframe_doc("notes").getElementsByName("note-" + ref_name)[0]
