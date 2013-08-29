// Generated by CoffeeScript 1.4.0
(function() {
  var CMD_SYNC_AMF, CMD_SYNC_GRAPHICS, CMD_SYNC_TIMESTAMPE, CMD_TEST_AMF, CURRENT_JOB, JOB_SYNC_AMF, JOB_SYNC_GRAPHICS, JOB_SYNC_TIMESTAMP, KV_CLIENTS, PATH_TO_CONFIG_FOLDER, PATH_TO_SYNCER, REG_FILTER_AMF, REG_FILTER_GRAPHICS, REG_FILTER_TIMESTAMP, TEMPLATE_JOB, app, child_process, env, fs, io, logger, runJob, server, util;

  app = require('express')();

  server = require('http').createServer(app);

  io = require('socket.io').listen(server);

  util = require('util');

  logger = require('dev-logger');

  child_process = require('child_process');

  env = require('./environment');

  fs = require('fs');

  CURRENT_JOB = null;

  PATH_TO_SYNCER = "" + __dirname + "/node_modules/upyun-assets-syncer/bin/upsyncer.coffee";

  PATH_TO_CONFIG_FOLDER = "" + __dirname + "/temp_conf/";

  JOB_SYNC_GRAPHICS = [PATH_TO_SYNCER];

  JOB_SYNC_AMF = [PATH_TO_SYNCER];

  JOB_SYNC_TIMESTAMP = [PATH_TO_SYNCER];

  CMD_SYNC_GRAPHICS = 'sync_graphics';

  CMD_SYNC_AMF = 'sync_amf';

  CMD_TEST_AMF = 'test_amf';

  CMD_SYNC_TIMESTAMPE = 'sync_timestamp';

  TEMPLATE_JOB = "{\n\n  \"LOCAL_DEPOT_ROOT\" : \"" + env.LOCAL_DEPOT_ROOT + "\",\n\n  \"REGEX_FILE_NAME\" : {regFileFilter},\n\n  \"BUCKETNAME\" : \"" + env.BUCKETNAME + "\",\n\n  \"USERNAME\" : \"" + env.USERNAME + "\",\n\n  \"PASSWORD\" : \"" + env.PASSWORD + "\",\n\n  \"REVISION_SENSITIVE\" : {revisionSensitive},\n\n  \"PARALLELY\" : false,\n\n  \"VERBOSE\" : true,\n\n  \"WALK_OPTIONS\" : {\n    \"followLinks\" : false\n  }\n\n}";

  REG_FILTER_AMF = /_[a-z0-9]{10}\.sgf/;

  REG_FILTER_TIMESTAMP = /_amflastmod\.sgf/;

  REG_FILTER_GRAPHICS = /[a-z0-9]{11}\.sgf/;

  KV_CLIENTS = {};

  server.listen(8088);

  app.get('/', function(req, res) {
    return res.sendfile(__dirname + '/index.html');
  });

  runJob = function(regexpFilter, revisionSensitive, istest) {
    var argsArr, content, error, pathToSyncJobJson;
    if (istest == null) {
      istest = false;
    }
    if (regexpFilter == null) {
      error = "[server::compileJobConf] bad argument. " + arguments;
      return;
    }
    if (CURRENT_JOB != null) {
      io.sockets.emit('error', {
        message: "当前正有一个任务在进行，请等待当前任务完成后在进行操作"
      });
      return;
    }
    content = TEMPLATE_JOB.replace('{regFileFilter}', regexpFilter.toString()).replace('{revisionSensitive}', Boolean(revisionSensitive));
    if (!fs.existsSync(PATH_TO_CONFIG_FOLDER)) {
      fs.mkdirSync(PATH_TO_CONFIG_FOLDER);
    }
    pathToSyncJobJson = "" + PATH_TO_CONFIG_FOLDER + "sync_job.json";
    fs.writeFileSync(pathToSyncJobJson, content);
    logger.log("[server::runJob] pathToSyncJobJson:" + pathToSyncJobJson + ", content:" + content);
    argsArr = ['-c', pathToSyncJobJson];
    if (istest) {
      argsArr.push('-t');
    }
    CURRENT_JOB = child_process.spawn.apply(null, [PATH_TO_SYNCER, argsArr]);
    CURRENT_JOB.stdout.on('data', function(data) {
      data = String(data);
      console.log('stdout: ' + data);
      io.sockets.emit('log', {
        message: data
      });
    });
    CURRENT_JOB.stderr.on('data', function(data) {
      data = String(data);
      console.log('stderr: ' + data);
      io.sockets.emit('error', {
        message: data
      });
    });
    CURRENT_JOB.on('close', function(code) {
      console.log('child process exited with code ' + code);
      CURRENT_JOB.removeAllListeners();
      return CURRENT_JOB = null;
    });
  };

  io.sockets.on('connection', function(socket) {
    KV_CLIENTS[socket.id] = socket;
    io.sockets.emit('log', {
      message: "client " + socket.id + " connected"
    });
    return socket.on('action', function(data) {
      logger.log("[server::on::action] cmd:" + data.cmd);
      switch (data.cmd) {
        case CMD_SYNC_GRAPHICS:
          runJob(REG_FILTER_GRAPHICS, false);
          break;
        case CMD_SYNC_AMF:
          runJob(REG_FILTER_AMF, true);
          break;
        case CMD_TEST_AMF:
          runJob(REG_FILTER_AMF, true, true);
          break;
        case CMD_SYNC_TIMESTAMPE:
          runJob(REG_FILTER_TIMESTAMP, true);
      }
    });
  });

  return;

}).call(this);
