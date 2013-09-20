default[:td_agent][:api_key] = ''

default[:td_agent][:plugins] = ["udp" , "redshift"]
default[:td_agent][:version] = "1.1.15-1"
default[:td_agent][:s3endpoint] = "s3-us-west-2.amazonaws.com"
default[:td_agent][:s3bucket] = "kwarter-redshift-us-west-2"


default[:td_agent][:redshift][:host] = "kwarter.cokd89y6juoz.us-west-2.redshift.amazonaws.com"
default[:td_agent][:redshift][:port] = "5439"
default[:td_agent][:redshift][:dbname] = "dev"
default[:td_agent][:redshift][:user] = "platforms"
default[:td_agent][:redshift][:password] = "Kwart3rMast3r"
default[:td_agent][:redshift][:filetype] = "json"