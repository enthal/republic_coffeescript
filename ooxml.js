(function() {
  var do_body, fs, local_name, log, parser, reader, sax_reader, write_to, xml_str;

  log = console.log;

  parser = require("sax").parser(true);

  sax_reader = require("./sax_reader");

  reader = sax_reader.attach(parser, {
    onopentag: function(node, push_delegate) {
      if (node.name !== "office:document") throw "Need: <office:document>";
      return push_delegate({
        onopentag: function(node, push_delegate) {
          if (node.name === "office:body") {
            return do_body(push_delegate);
          } else {
            return push_delegate({});
          }
        }
      });
    }
  });

  do_body = function(push_delegate) {
    var f_note, f_text, make_body_delegate, make_note_delegate;
    try {
      fs.mkdirSync("OUT");
    } catch (_error) {}
    f_text = fs.openSync("OUT/text.html", "w+");
    f_note = fs.openSync("OUT/notes.html", "w+");
    make_body_delegate = function(f) {
      var html_tags_by_name;
      html_tags_by_name = {
        "text:p": "p",
        "text:span": "span",
        "text:h": "h1"
      };
      return {
        ontext: function(text) {
          return write_to(f, text);
        },
        onopentag: function(node, push_delegate) {
          var classing, space, style_name, tag_name;
          tag_name = html_tags_by_name[node.name];
          if (tag_name) {
            space = tag_name === "span" ? "" : "\n";
            style_name = node.attributes["text:style-name"];
            classing = (" class='" + style_name + "'")(style_name ? void 0 : "");
            return write_to(f, "" + space + "<" + tag_name + classing + ">");
          } else {
            switch (node.name) {
              case "text:note":
                return push_delegate(make_note_delegate());
              case "text:note-ref":
                write_to(f_note, "<A href='\#" + node.attributes["text:ref-name"] + "'>");
                return push_delegate(make_body_delegate(f_note));
            }
          }
        },
        onclosetag: function(name) {
          var tag_name;
          tag_name = html_tags_by_name[name];
          if (tag_name) {
            return write_to(f, "</" + tag_name + ">");
          } else {
            switch (name) {
              case "text:note-ref":
                return write_to(f_note, "</A>");
            }
          }
        }
      };
    };
    make_note_delegate = function() {
      return {
        ontext: function(text) {
          var f, _i, _len, _ref, _results;
          text = text.trim();
          _ref = [f_text, f_note];
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            f = _ref[_i];
            _results.push(write_to(f, text));
          }
          return _results;
        },
        onopentag: function(node, push_delegate) {
          var note_id;
          note_id = this.base_node.attributes['text:id'];
          switch (node.name) {
            case "text:note-citation":
              write_to(f_text, "<A href='notes.html\#" + note_id + "' name='" + note_id + "'>");
              return write_to(f_note, "\n<div>\n<a href='text.html\#" + note_id + "' name='" + note_id + "'><b>");
            case "text:note-body":
              return push_delegate(make_body_delegate(f_note));
          }
        },
        onclosetag: function(name) {
          switch (name) {
            case "text:note-citation":
              write_to(f_text, "</A>");
              return write_to(f_note, "</b></a>");
            case "text:note-body":
              return write_to(f_note, "\n</div>\n");
          }
        }
      };
    };
    return push_delegate(make_body_delegate(f_text));
  };

  local_name = function(name) {
    var m;
    m = /.*:(.*)/.exec(name);
    return (m != null) && m[1] || name;
  };

  write_to = function(f, s) {
    return fs.writeSync(f, s);
  };

  fs = require("fs");

  log(process.argv);

  xml_str = fs.readFileSync(process.argv[2]);

  parser.write(xml_str.toString()).close();

}).call(this);
