top.onload = ->
  show_export_date()

window.show_export_date = ->
  export_date_text = get_iframe_doc("text").getElementById("text-data").getAttribute("data-export-date")
  top.document.getElementById("date-display").innerHTML = export_date_text.match(/(.*)T/)[1] or export_date_text

window.handle = (event) ->
  target = event.target || event.srcElement || event.toElement
  #console.log("***** handle:", target.className, event.type)
  #console.log(event)

  refd_note_div = -> get_iframe_doc("notes").getElementsByName("note-" + target.name)[0]
  note_ref = -> get_iframe_doc("text").getElementsByName(target.name.replace(/^note-/,''))[0]

  see_level = (get_destination) ->
    console.log "see_level!!!"
    old_scrollTop = get_destination().offsetParent.scrollTop
    wanted_scrollTop = get_destination().offsetTop - (target.offsetTop - target.offsetParent.scrollTop)
    if wanted_scrollTop < 0
      console.log "FAILED to scroll to #{wanted_scrollTop}... falling back"  # happens on firefox!
      return true

    # TODO: back off scroll by amount height of bottom part of note div scolled out of view, if any, but not past top of div
    if wanted_scrollTop != old_scrollTop
      get_destination().offsetParent.scrollTop = wanted_scrollTop
      if old_scrollTop == get_destination().offsetParent.scrollTop
        console.log "try firefox workaround"
        get_destination().offsetParent.parentElement.scrollTop = wanted_scrollTop  # firefox
        if old_scrollTop == get_destination().offsetParent.parentElement.scrollTop
          console.log "FAILED to scroll to #{wanted_scrollTop}... falling back"
          return true
    console.log "scrolled to #{wanted_scrollTop}"
    false

  controller =
    'CONV-note-reference':
      click: ->
        see_level refd_note_div
      mouseover: ->
        refd_note_div().style.backgroundColor = "#FFC"
      mouseout: ->
        refd_note_div().style.backgroundColor = null
    'CONV-note-identifier':
      click: ->
        see_level note_ref
    #'CONV-note':
      mouseover: ->
        note_ref().style.backgroundColor = "#FF3"
        note_ref().style.border = "2px solid red"
      mouseout: ->
        note_ref().style.backgroundColor = null
        note_ref().style.border = null
    'CONV-note':
      mouseover: -> console.log "mouseover"
      mouseout:  -> console.log "mouseout"

  for css_class in target.classList
    action = try controller[css_class][event.type]
    if action
      console.log "ACTION: #{css_class} : #{event.type}"
      return action target, event

  true

get_iframe_doc = (iframe_id) ->
  iframe = top.document.getElementById(iframe_id)
  iframe.content_document or iframe.contentWindow.document

