
# 设置表
settings =

  LOCAL_DEPOT_ROOT : "/path/to/asset"

  BUCKETNAME : "________"

  USERNAME : "_________"

  PASSWORD : "__________"


  # 加载外部配置的帮助方法
  load: (module) ->
    try
      localSettings = require module

      for own key, value of localSettings
        settings[key] = value
    catch e

settings.load "./local_environment"

module.exports = settings

