
app = require('express')()
server = require('http').createServer(app)
io = require('socket.io').listen(server)
util  = require 'util'
logger = require 'dev-logger'
child_process = require 'child_process'

CURRENT_JOB = null

PATH_TO_SYNCER = "#{__dirname}/node_modules/upyun-assets-syncer/bin/upsyncer.coffee"

JOB_SYNC_GRAPHICS = [PATH_TO_SYNCER]

JOB_SYNC_AMF = [PATH_TO_SYNCER]

JOB_SYNC_TIMESTAMP = [PATH_TO_SYNCER]

CMD_SYNC_GRAPHICS = 'sync_graphics'

CMD_SYNC_AMF = 'sync_amf'

CMD_SYNC_TIMESTAMPE = 'sync_timestamp'

# key: client socket id
# value: client socket instance
KV_CLIENTS = {}

# fire express and the socket server
server.listen(8088)

app.get '/', (req, res) ->
  res.sendfile(__dirname + '/index.html')

runJob = (config)->
  unless Array.isArray(config) and config.length > 0
    logger.error "[server::runJob] bad argument. config:#{config}"
    return

  # only one job at time
  if CURRENT_JOB?
    io.sockets.emit 'error',
      alert: "当前正有一个任务在进行，请等待当前任务完成后在进行操作"
    return

  CURRENT_JOB = child_process.spawn.apply(null, config)

  CURRENT_JOB.stdout.on 'data', (data) ->
    data = String(data)
    console.log('stdout: ' + data)
    io.sockets.emit 'log',
      message: data
    return

  CURRENT_JOB.stderr.on 'data', (data) ->
    data = String(data)
    console.log('stderr: ' + data)
    io.sockets.emit 'error',
      message: data
    return

  CURRENT_JOB.on 'close', (code) ->
    console.log('child process exited with code ' + code)
    CURRENT_JOB.removeAllListeners()
    CURRENT_JOB = null

  return

# when client connected
io.sockets.on 'connection', (socket) ->

  KV_CLIENTS[socket.id] = socket

  io.sockets.emit 'log',
    message : "client #{socket.id} connected"

  socket.on 'action', (data)->
    logger.log "[server::on::action] cmd:#{data.cmd}"
    switch data.cmd
      when CMD_SYNC_GRAPHICS
        runJob(JOB_SYNC_GRAPHICS)
      when CMD_SYNC_AMF
        runJob(JOB_SYNC_AMF)
      when CMD_SYNC_TIMESTAMPE
        runJob(JOB_SYNC_TIMESTAMP)
    return

return



