aws = require 'aws-lib'

sqs = aws.createSQSClient(
  process.env.AWS_ACCESS_KEY_ID,
  process.env.AWS_SECRET_ACCESS_KEY,
  path: "/633453528193/megillah" )

sys = require('sys')
exec = require('child_process').exec
exec("git status", (error, stdout, stderr) -> sys.puts(error, "stdout:", stdout, "stderr:", stderr) )


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
      exec("git status", (error, stdout, stderr) -> sys.puts(error, stdout.length, stderr.length) )

setInterval poll_sqs, (process.env.POLL_INTERVAL_SECS or 10) * 1000
