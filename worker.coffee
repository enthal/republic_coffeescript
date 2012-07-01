#! /usr/bin/env coffee

#log = console.log
crypto = require 'crypto'
fs = require 'fs'
util = require 'util'
child_process = require 'child_process'
path = require 'path'

aws = require 'aws-lib'
knox = require 'knox'
coffee_script = require 'coffee-script'

ooxml = require './ooxml'

sqs = aws.createSQSClient(
  process.env.AWS_ACCESS_KEY_ID,
  process.env.AWS_SECRET_ACCESS_KEY,
  path: "/633453528193/megillah" )

s3 = knox.createClient(
  key: process.env.AWS_ACCESS_KEY_ID,
  secret: process.env.AWS_SECRET_ACCESS_KEY,
  bucket: process.env.S3_BUCKET or 'tjames-x' )

pull_and_process = (repo_url) ->
  temp_dir = path.join "/tmp", crypto.randomBytes(4).toString('hex')
  child_process.exec "git clone --depth=1 #{repo_url} #{temp_dir}", (error, stdout, stderr) ->
    util.puts(error, "stdout:", stdout, "stderr:", stderr)

    xml_filename = path.join temp_dir, 'RepublicCommentary_Quandt.xml'

    ooxml.run xml_filename  # synchronous

    console.log "Done converting"
    child_process.exec("rm -r #{temp_dir}")

    # TODO: don't output into decendent of app (cwd) directory (./public/OUT), but into a temp dir we can remove!
    console.log fs.readdirSync 'public'
    console.log fs.readdirSync 'public/OUT'

    count = 0
    for_each_file 'public', (filename) ->
      s3_path = filename[("public/".length)..-1]
      if '.coffee' == path.extname filename
        console.log "COMPILE #{filename} ..."
        compiled_text = coffee_script.compile fs.readFileSync(filename).toString()
        s3_path = s3_path.replace /\.coffee$/, '.js'
        console.log "... UPLOAD #{s3_path} ;"
        s3.put s3_path,
          'Content-Length': compiled_text.length,
          'Content-Type': 'application/javascript'
        .end(compiled_text)  # TODO: count++/count-- with potential logging in a response handler
      else
        console.log "UPLOAD #{filename} (#{s3_path}) ..."
        count++
        s3.putStream fs.createReadStream(filename), s3_path, (err,res) ->
          console.log "... UP #{filename} (#{s3_path}) END: ", err, res.statusCode
          console.log "ALL DONE!"  unless --count

for_each_file = (dir_name, on_each_f) ->
  for name in fs.readdirSync dir_name
    full_name = path.join dir_name, name
    stat = fs.statSync full_name
    on_each_f full_name if stat.isFile()
    for_each_file full_name, on_each_f if stat.isDirectory()

poll_sqs = ->
  sqs.call "ReceiveMessage", {}, (err, result) ->
    if err then console.log "ReceiveMessage error: #{err}"
    #console.log result
    message = result.ReceiveMessageResult.Message
    unless message
      console.log "no message this time"
      return
    #console.log message
    try
      body = JSON.parse message.Body
      #console.log body
      repo = body.repository
      console.log body.pusher, repo.name, repo.url
      console.log body.head_commit.message
      pull_and_process "#{repo.url}.git"
    catch error
      console.log error
    finally
      # TODO: delete only after processing complete!  Re-enqueue on fail?
      sqs.call "DeleteMessage", {ReceiptHandle:message.ReceiptHandle}, (err, result) ->
        if err
          console.log "DeleteMessage error: #{err}"

      console.log 'ok!'

setInterval poll_sqs, (process.env.POLL_INTERVAL_SECS or 10) * 1000
