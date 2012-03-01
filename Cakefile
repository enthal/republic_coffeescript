task 'all', 'do everything locally', (options) ->
  console.log "TODO all"

task 'install', 'do all then push to S3', (options) ->
  invoke 'all'
  console.log "TODO install"

{spawn} = require 'child_process'

task 'watch', -> spawn 'coffee', ['-cw', 'public'], customFds: [0..2]
