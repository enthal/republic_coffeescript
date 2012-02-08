#! /usr/bin/env coffee

log = console.log

parser = require("sax").parser true

sax_reader = require("./sax_reader")

reader = sax_reader.attach parser,
  onopentag:  (node) -> log reader.depth(), "OPEN ", node
  onclosetag: (name) -> log reader.depth(), "CLOSE", name
  ontext:     (text) -> log reader.depth(), "TEXT:", text

fs = require "fs"
log process.argv
xml_str = fs.readFileSync(process.argv[2])
parser.write(xml_str.toString()).close()
