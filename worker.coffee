aws = require ('aws-lib')

access_key_id     = "AKIAIR4Y6GNQFCN4T7UA"
secret_access_key = "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"

options = {
  "path" : "/633453528193/megillah"
}

sqs = aws.createSQSClient(access_key_id, secret_access_key, options)

#outbound = {
#  MessageBody : JSON.stringify({
#    data: "Test Message from nodejs worker",
#    timestamp: new Date().getTime()
#    })
#}

#sqs.call "SendMessage", outbound, (err, result) ->
#  if err then console.log "SendMessage error: #{err}"
#  console.log result

sqs.call "ReceiveMessage", {}, (err, result) ->
  if err then console.log "ReceiveMessage error: #{err}"
  #console.log result
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
