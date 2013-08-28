
app = require('express')()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

server.listen(8088)

app.get '/', (req, res) ->
  res.sendfile(__dirname + '/index.html')

io.sockets.on 'connection', (socket) ->
  socket.emit 'news',
    hello: 'world'

  count = 0
  setInterval ()->
    socket.emit 'news',
      count: ++count
  , 2000

  socket.on 'action', (data)->
    console.log(data)

return
