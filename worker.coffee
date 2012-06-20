# Here is a worker; I love workers!!

aws = require 'aws-lib'

sqs = aws.createSQSClient(
  process.env.AWS_ACCESS_KEY_ID,
  process.env.AWS_SECRET_ACCESS_KEY,
  path: "/633453528193/megillah" )

if false
  outbound =
    MessageBody : JSON.stringify(
      data: "Test Message from nodejs worker",
      timestamp: new Date().getTime()
      )

  sqs.call "SendMessage", outbound, (err, result) ->
    if err then console.log "SendMessage error: #{err}"
    console.log result

sqs.call "ReceiveMessage", {}, (err, result) ->
  if err then console.log "ReceiveMessage error: #{err}"
  console.log result
  message = result.ReceiveMessageResult.Message
  return unless message
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
