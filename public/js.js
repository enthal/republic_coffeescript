function onload() {
  crosslink_text_notes();
  show_export_date();
}

function show_export_date() {
  var inner_doc = get_iframe_doc('text');
  var export_date = inner_doc.getElementById('text-data').getAttribute('data-export-date');

  var span = document.getElementById('date-display');
  span.innerText = new Date(export_date).toString();
}

function get_iframe_doc(iframe_id) {
  var iframe = document.getElementById(iframe_id);
  return iframe.content_document || iframe.contentWindow.document;
}

function crosslink_text_notes() {
  var text_doc  = get_iframe_doc('text');
  var notes_doc = get_iframe_doc('notes');

  text_doc.notes_doc = notes_doc;
  notes_doc.text_doc = text_doc;
}

function on_note_ref_click (target, event) {
  return true;
}

function on_note_ref_mouseover (target, event) {
  get_note_div(target.name).style.backgroundColor = '#FFC';
}

function on_note_ref_mouseout (target, event) {
  get_note_div(target.name).style.backgroundColor = null;
}

function get_note_div(ref_name) {
  return document.notes_doc.getElementsByName('note-'+ref_name)[0];
}

function on_note_ident_click (target, event) {
  return true;
}

function on_note_ident_mouseover (target, event) {
}

function on_note_ident_mouseout (target, event) {
}
