#! /usr/bin/env coffee

#log = console.log
crypto = require 'crypto'
fs = require 'fs'
util = require 'util'
child_process = require 'child_process'
path = require 'path'

aws = require 'aws-lib'
knox = require 'knox'

ooxml = require './ooxml'

sqs = aws.createSQSClient(
  process.env.AWS_ACCESS_KEY_ID,
  process.env.AWS_SECRET_ACCESS_KEY,
  path: "/633453528193/megillah" )

s3 = knox.createClient(
  key: process.env.AWS_ACCESS_KEY_ID,
  secret: process.env.AWS_SECRET_ACCESS_KEY,
  bucket: 'tjames-x' )

console.log process.cwd()
console.log fs.readdirSync '.'

#child_process.exec("git status", (error, stdout, stderr) -> util.puts(error, "stdout:", stdout, "stderr:", stderr) )

pull_and_process = (repo_url) ->
  temp_dir = path.join "/tmp", crypto.randomBytes(4).toString('hex')
  child_process.exec "git clone --depth=1 #{repo_url} #{temp_dir}", (error, stdout, stderr) ->
    util.puts(error, "stdout:", stdout, "stderr:", stderr)
    #child_process.exec("git status", (error, stdout, stderr) -> util.puts(error, "stdout:", stdout, "stderr:", stderr) )

    xml_filename = path.join temp_dir, 'RepublicCommentary_Quandt.xml'
    s3.putFile xml_filename, "xml.xml", (err,res) -> console.log "S3 put result", err, res.statusCode

    ooxml.run xml_filename  # synchronous

    console.log "Done converting"
    console.log fs.readdirSync 'public'
    console.log fs.readdirSync 'public/OUT'

    child_process.exec("rm -r #{temp_dir}")


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
