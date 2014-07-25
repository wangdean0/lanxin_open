# LanxinOpen

Lanxin is Real-time communication application for enterprise internal communicate,with full client support,including Android, iOS, Windows,Mac,Web etc.The Openplatform give the thirdpart company provide service through Lanxin.More information please refer to http://lanxin.cn.

## Installation

Add this line to your application's Gemfile:

    gem 'lanxin_open'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lanxin_open

## Usage

configure the LanxinOpen while init,like following code;
```
LanxinOpen.config do
  host "https://open-dev.lanxin.cn" #"http://118.192.68.146"
  port ""
  use_new_json true
end
```
then while you want to call the interface,call like this
```
open = LanxinOpen.new
skey = open.fetch_skey("token","devkey")
puts "fetch skey: #{skey}"
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/lanxin_open/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
