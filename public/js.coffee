top.onload = ->
  show_export_date()

window.show_export_date = ->
  export_date_text = get_iframe_doc("text").getElementById("text-data").getAttribute("data-export-date")
  top.document.getElementById("date-display").innerHTML = export_date_text.match(/(.*)T/)[1] or export_date_text

window.handle = (event) ->
  target = event.target || event.srcElement || event.toElement
  #console.log("***** handle:", target.className, event.type)
  #console.log(event)
  refd_note_div = -> get_note_div(target.name)

  controller =
    'CONV-note-reference':
      click: ->
        # See-level!!
        event.pageY ?= event.clientY + document.documentElement.scrollTop  # special IE case
        console.log  "CLICK!"
        lp = ->
          console.log(
            event.clientY, event.pageY, 
            target.offsetTop,  target.offsetParent.scrollTop,
            target.offsetTop - target.offsetParent.scrollTop,
            refd_note_div().offsetTop, 
            refd_note_div().offsetParent.scrollTop,
            refd_note_div().offsetTop - (target.offsetTop - target.offsetParent.scrollTop) )
        lp()
        #refd_note_div().scrollIntoView(true)
        old_scrollTop = refd_note_div().offsetParent.scrollTop
        wanted_scrollTop = refd_note_div().offsetTop - (target.offsetTop - target.offsetParent.scrollTop)
        # TODO: back off scroll by amount height of bottom part of note div scolled out of view, if any, but not past top of div
        if wanted_scrollTop != old_scrollTop
          refd_note_div().offsetParent.scrollTop = wanted_scrollTop
          lp()
          if old_scrollTop == refd_note_div().offsetParent.scrollTop
            refd_note_div().offsetParent.parentElement.scrollTop = wanted_scrollTop  # firefox
            if old_scrollTop == refd_note_div().offsetParent.parentElement.scrollTop
              console.log "FAILED to scroll to #{wanted_scrollTop}... falling back"
              return true
          else
            console.log "scrolled to #{wanted_scrollTop}"
        console.log event
        false
      mouseover: (target, event) ->
        refd_note_div().style.backgroundColor = "#FFC"
      mouseout:  (target, event) ->
        refd_note_div().style.backgroundColor = null
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
