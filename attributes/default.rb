default[:td_agent][:api_key] = ''

default[:td_agent][:plugins] = []
default[:td_agent][:version] = nil
default[:td_agent][:s3endpoint] = nil
default[:td_agent][:s3bucket] = nil


default[:td_agent][:redshift][:host] = nil
default[:td_agent][:redshift][:port] = nil
default[:td_agent][:redshift][:dbname] = nil
default[:td_agent][:redshift][:user] = nil
default[:td_agent][:redshift][:password] = nil
default[:td_agent][:redshift][:filetype] = nil

default[:td_agent][:includes] = false
default[:td_agent][:default_config] = true
default[:td_agent][:in_http][:enable_api] = true
default[:td_agent][:version] = '1.1.19'
default[:td_agent][:pinning_version] = false
default[:td_agent][:in_forward] = {
  port: 24224,
  bind: '0.0.0.0'
}
default[:td_agent][:in_http] = {
  port: 8888,
  bind: '0.0.0.0'
}
