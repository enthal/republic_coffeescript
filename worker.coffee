aws = require 'aws-lib'

sqs = aws.createSQSClient(
  process.env.AWS_ACCESS_KEY_ID,
  process.env.AWS_SECRET_ACCESS_KEY,
  path: "/633453528193/megillah" )

crypto = require 'crypto'
fs = require 'fs'
util = require 'util'
exec = require('child_process').exec
exec("git status", (error, stdout, stderr) -> util.puts(error, "stdout:", stdout, "stderr:", stderr) )
temp_dir = "/tmp/#{crypto.randomBytes(4).toString('hex')}"
fs.mkdirSync temp_dir
process.chdir temp_dir

#git_command = 'git clone --depth=1 git://github.com/enthal/ignore.git'
git_command = 'git clone --depth=1 git://github.com/kquandt/commentary.git'
exec git_command, (error, stdout, stderr) ->
  util.puts(error, "stdout:", stdout, "stderr:", stderr)
  process.chdir "./commentary"
  #exec("git status", (error, stdout, stderr) -> util.puts(error, "stdout:", stdout, "stderr:", stderr) )
  buf = fs.readFileSync('RepublicCommentary_Quandt.xml')
  console.log buf.length
  console.log buf.slice(0,100).toString()


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
      info = JSON.parse message.Body
      console.log info
    catch error
      console.log error
    finally
      sqs.call "DeleteMessage", {ReceiptHandle:message.ReceiptHandle}, (err, result) ->
        if err
          console.log "DeleteMessage error: #{err}"

      console.log 'ok!'
      exec("git status", (error, stdout, stderr) -> util.puts(error, stdout.length, stderr.length) )

setInterval poll_sqs, (process.env.POLL_INTERVAL_SECS or 10) * 1000
