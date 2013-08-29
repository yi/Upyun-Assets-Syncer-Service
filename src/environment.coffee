
# 设置表
settings =

  ASSETS_PATH : "/path/to/asset"

  UPYUN_BUCKETNAME : "________"

  UPYUN_USERNAME : "_________"

  UPYUN_PASSWORD : "__________"


  # 加载外部配置的帮助方法
  load: (module) ->
    try
      localSettings = require module

      for own key, value of localSettings
        settings[key] = value
    catch e

settings.load "./local_environment"

module.exports = settings

