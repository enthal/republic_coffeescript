top.onload = ->
  show_export_date()

window.show_export_date = ->
  export_date_text = get_iframe_doc("text").getElementById("text-data").getAttribute("data-export-date")
  top.document.getElementById("date-display").innerHTML = export_date_text.match(/(.*)T/)[1] or export_date_text

window.handle = (event) ->
  target = event.target || event.srcElement || event.toElement
  #if event.type is 'scroll'
  #  console.log("***** handle:", target.className, event.type)
  #  console.log(event)

  refd_note_div = -> get_iframe_doc("notes").getElementsByName("note-" + target.name)[0]
  note_ref      = -> get_iframe_doc("text") .getElementsByName(target.name.replace(/^note-/,''))[0]

  see_level = (get_destination) ->
    # TODO: back off scroll by amount height of bottom part of note div scolled out of view, if any, but not past top of div
    get_destination().offsetParent.scrollTop = get_destination().offsetTop - (target.offsetTop - target.offsetParent.scrollTop)
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
    'scroll-container':
      scroll: ->
        scrollTop = event.target.scrollTop
        scrollBottom = scrollTop + event.target.offsetParent.clientHeight
        bmrs = get_iframe_doc("text").getElementsByClassName("CONV-bookmark-reference")  # TODO IE polyfill
        #console.log "scroll", scrollTop, scrollBottom#, bmrs.length, [0...bmrs.length]
        for i in [0...bmrs.length]
          [bmr, bmr_next] = [bmrs[i], bmrs[i+1]]
          bm = get_iframe_doc("bookmarks").getElementsByName(bmr.name)[0]
          if bm
            if bmr.offsetTop < scrollBottom and (!bmr_next or bmr_next.offsetTop > scrollBottom)
              bm.classList.add "bookmark-visible"  # TODO IE polyfill
            else
              bm.classList.remove "bookmark-visible"

  for css_class in target.classList
    action = try controller[css_class][event.type]
    if action
      #console.log "ACTION: #{css_class} : #{event.type}"
      return action target, event

  true

get_iframe_doc = (iframe_id) ->
  iframe = top.document.getElementById(iframe_id)
  iframe.content_document or iframe.contentWindow.document
