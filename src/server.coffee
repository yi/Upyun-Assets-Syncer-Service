
app = require('express')()
server = require('http').createServer(app)
io = require('socket.io').listen(server)
util  = require 'util'
logger = require 'dev-logger'
child_process = require 'child_process'
env = require './environment'
fs = require 'fs'
_ = require "underscore"


CURRENT_JOB = null

PATH_TO_SYNCER = "#{__dirname}/node_modules/upyun-assets-syncer/bin/upsyncer.coffee"

PATH_TO_CONFIG_FOLDER = "#{__dirname}/temp_conf/"

JOB_SYNC_GRAPHICS = [PATH_TO_SYNCER]

JOB_SYNC_AMF = [PATH_TO_SYNCER]

JOB_SYNC_TIMESTAMP = [PATH_TO_SYNCER]

CMD_SYNC_GRAPHICS = 'sync_graphics'

CMD_SYNC_AMF = 'sync_amf'

CMD_TEST_AMF = 'test_amf'

CMD_SYNC_TIMESTAMPE = 'sync_timestamp'

CMD_SYNC_WUID = 'sync_wuid'


TEMPLATE_JOB = """
{

  "LOCAL_DEPOT_ROOT" : "#{env.LOCAL_DEPOT_ROOT}{subPath}",

  "REGEX_FILE_NAME" : {regFileFilter},

  "BUCKETNAME" : "#{env.BUCKETNAME}",

  "USERNAME" : "#{env.USERNAME}",

  "PASSWORD" : "#{env.PASSWORD}",

  "REVISION_SENSITIVE" : {revisionSensitive},

  "PARALLELY" : false,

  "VERBOSE" : true,

  "WALK_OPTIONS" : {
    "followLinks" : false
  }

}
"""

REG_FILTER_AMF = /_[a-z0-9]{10}\.sgf/

REG_FILTER_TIMESTAMP = /_amflastmod\.sgf/

REG_FILTER_GRAPHICS = /[a-z0-9]{11}\.sgf/

# console.log("TEMPLATE_JOB:"+TEMPLATE_JOB)

# key: client socket id
# value: client socket instance
KV_CLIENTS = {}

# fire express and the socket server
server.listen(8088)

app.get '/', (req, res) ->
  res.sendfile(__dirname + '/index.html')

# compile a job config
# @param {RegExp} regexpFilter
# @param {Boolean} revisionSensitive
runJob = (regexpFilter, revisionSensitive, subPath='', istest=false) ->

  unless regexpFilter?
    error = "[server::compileJobConf] bad argument. #{arguments}"
    return

  # only one job at time
  if CURRENT_JOB?
    io.sockets.emit 'error',
      message : "当前正有一个任务在进行，请等待当前任务完成后在进行操作"
    return

  content = TEMPLATE_JOB.
    replace('{regFileFilter}', regexpFilter.toString()).
    replace('{revisionSensitive}',Boolean(revisionSensitive)).
    replace('{subPath}', subPath)

  fs.mkdirSync(PATH_TO_CONFIG_FOLDER) unless fs.existsSync(PATH_TO_CONFIG_FOLDER)

  pathToSyncJobJson = "#{PATH_TO_CONFIG_FOLDER}sync_job.json"

  fs.writeFileSync pathToSyncJobJson, content

  logger.log "[server::runJob] pathToSyncJobJson:#{pathToSyncJobJson}, content:#{content}"

  argsArr = ['-c', pathToSyncJobJson]
  argsArr.push '-t' if istest
  CURRENT_JOB = child_process.spawn.apply(null, [PATH_TO_SYNCER, argsArr])

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
        runJob(REG_FILTER_GRAPHICS, false)

      when CMD_SYNC_AMF
        runJob(REG_FILTER_AMF, true, "/_")

      when CMD_TEST_AMF
        runJob(REG_FILTER_AMF, true, "/_", true)

      when CMD_SYNC_TIMESTAMPE
        runJob(REG_FILTER_TIMESTAMP, true , "/_")

      when CMD_SYNC_WUID
        wuid = data.wuid
        if _.isString(wuid) and wuid.length is 11
          runJob("/#{wuid}\\.sgf/", true , "/#{wuid.charAt(0)}")
        else
          io.sockets.emit 'error',
            message : "bad wuid:#{wuid}"
      else
        io.sockets.emit 'error',
          message : "unknow action:#{data.cmd}"
    return

return


