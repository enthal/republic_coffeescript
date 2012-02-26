function show_export_date() {
  var iframe = document.getElementById('text');
  var innerDoc = iframe.contentDocument || iframe.contentWindow.document;
  var export_date = innerDoc.getElementById('text-data').getAttribute('data-export-date');

  var span = document.getElementById('date-display');
  span.innerText = new Date(export_date).toString();
}