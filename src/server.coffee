
app = require('express')()
server = require('http').createServer(app)
io = require('socket.io').listen(server)
util  = require 'util'
logger = require 'dev-logger'

{spawn} = require 'child_process'

CURRENT_JOB = null

JOB_SYNC_ASSET = ["#{__dirname}/node_modules/upyun-assets-syncer/bin/upsyncer.coffee"]

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

runJob = (configj)->
  # only one job at time
  if IS_BUSY
    io.sockets.emit 'error',
      contennt: "当前正有一个任务在进行，请等待当前任务完成后在进行操作"
    return





# when client connected
io.sockets.on 'connection', (socket) ->

  KV_CLIENTS[socket.id] = socket

  io.sockets.emit 'log',
    contennt: "client #{socket.id} connected"

  socket.on 'action', (data)->
    switch data.cmd
      when CMD_SYNC_GRAPHICS
        console.log data.cmd
      when CMD_SYNC_AMF
        console.log data.cmd
      when CMD_SYNC_TIMESTAMPE
        console.log data.cmd
    return

return





        #ls    = spawn('ls', ['-lh', '/usr']);





