require "lanxin_open/net_util"

module LanxinOpen
	module Platform
    attr_accessor :skey
    attr_accessor :host,:port,:use_new_json

    def dump_config
      puts "test_config #{host}, #{port}, #{use_new_json}"
    end

    def host_with_port
      if port and port.length > 0
        "#{host}:#{port}"
      else
        host
      end
    end

    def lx_url(path)
      unless path.start_with?("/")
        path = "/" + path
      end
      "#{host_with_port}#{path}"
    end

    def content_utf8(content,source_charset="gbk")
      return content unless source_charset
      begin
        # converter = Iconv.new 'UTF-8//IGNORE', source_charset
        converter = Iconv.new 'UTF-8', source_charset
        utf8_str = converter.iconv content
      rescue Exception => e
        return content
      end
    end

    def encode_resbody(body)
      source_charsets = ["gbk","gb2312"]
      i = 0
      begin
        gbk = body.encode("utf-8", source_charsets[i])
        return gbk
      rescue Exception => e
        if i < source_charsets.length
          i +=1
          retry
        end
      end
      gbk = content_utf8(body,"gbk")
    end

    def fetch_skey(token,devkey)
      req_url = lx_url("/opc/ishow")
      params = {
        "p_id"   => "131",
        "t_id"   => "18", 
        "d_id"   => "1",
        "url"    => "/logintoskey.html", 
        "token"  => token,
        "devkey" => devkey
      }
      # body = encode_resbody(NetUtil.post_req(req_url,params).body)
      begin
        body = encode_resbody(NetUtil.post_req(req_url,params).body)
        puts body
        ret = JSON.parse(body.to_s)
        if ret["state"] == "OK"
          @skey= ret["sessionKey"]
        end
      rescue
      end
    end

    #new interface use UTF-8 charset
    def member_get(org_id,open_id)
      req_url = lx_url("cgi-bin/member/get")
      params = {
        "access_token" => skey,
        "orgId" => org_id,
        "mobile" => open_id,
      }
      body = NetUtil.post_req(req_url,params).body
    end

    #new interface use UTF-8 charset
    # query_type:
    #     0:get struct node;  1: get user node;  -1:get all node
    def org_get(org_id,struct_id,query_type)
      req_url = lx_url("cgi-bin/org/struct/parent/get")
      params = {
        "access_token" => skey,
        "orgId" => org_id,
        "structId" => struct_id,
        "orgStructType" => query_type
      }
      body = NetUtil.post_req(req_url,params).body
    end

  end

	class OpenPlatformV1
    include Platform

    def initialize(args)
      @host = args[:host] || LanxinOpen.host
      @port = args[:port] || LanxinOpen.port
      @use_new_json = args[:use_new_json] || LanxinOpen.use_new_json
    end

    def kehu_msg(fieldvalue,from_user)
      req_url = lx_url("/opc/ishow")
      params = {
        "p_id"   => "131",
        "t_id"   => "5",
        "d_id"   => "0",
        "url"    => "/customermessage/${docid}.shtml",
        "skey"   => skey,
        "_fieldvalue_msgcontent" => fieldvalue.to_json
      }
      body = encode_resbody(NetUtil.post_req(req_url,params).body)
    end

    def send_text_msg(txt_msg,open_id,from_user)
      text_json = {"content" => txt_msg}
      base_json = {
        "ToUserName" => open_id,
        "FromUserName" => from_user,
        "msgtype" => "text",
        "text" => text_json.to_json
      }
      base_json["text"] = text_json if use_new_json
      body = kehu_msg(base_json,from_user)
    end

    def send_link_msg(url,open_id,from_user)
      base_json = {
        "ToUserName" => open_id,
        "FromUserName" => from_user,
        "msgtype" => "link",
        "url" => url
      }
      body = kehu_msg(base_json,from_user)
    end

    def send_pictext_msg(url,open_id,title,from_user)
      news_json = {"url" => url}
      base_json = {
        "ToUserName" => open_id,
        "FromUserName" => from_user,
        "msgtype" => "news",
        "title" => title,
        "news" => news_json
      }
      # base_json["news"] = news_json if use_new_json
      body = kehu_msg(base_json,from_user)
    end

    def send_mail_msg(url,open_id,title,from_user)
      news_json = {"url" => url}
      base_json = {
        "ToUserName" => open_id,
        "FromUserName" => from_user,
        "msgtype" => "mail",
        "news" => news_json,
        "title" => title
      }
      body = kehu_msg(base_json,from_user)
    end

    def create_menu(menu_json)
      params = {
        "p_id" => 131,
        "t_id" => 15,
        "d_id" => 1,
        "url" => "/insert_menu.shtml",
        "menucontent" => menu_json.to_json,
        "skey" => skey
      }
      req_url = lx_url("/opc/ishow")
      body = encode_resbody(NetUtil.post_req(req_url,params).body)
    end

    def show_menu(publicno)
      params = {
        "p_id" => 131,
        "t_id" => 16,
        "d_id" => 1,
        "url" => "/query_menu.shtml",
        "publicno" => publicno,
        "skey" => skey
      }
      req_url = lx_url("/opc/ishow")
      body = encode_resbody(NetUtil.post_req(req_url,params).body)
    end

    def del_menu
      req_url = lx_url("/opc/ishow")
      params = {
        "p_id" => 131,
        "t_id" => 17,
        "d_id" => 1,
        "url"  => "/delmenu.shtml",
        "skey" => skey
      }
      body = encode_resbody(NetUtil.post_req(req_url,params).body)
    end

    def mem_info(mobile=nil,email=nil,orgid=nil)
      req_url = lx_url("/cgi-bin/member/get")
      params = {
        "access_token" => skey,
        "orgId" => orgid,
        "mobile" => mobile,
        "email"  => email,
      }
      body = encode_resbody(NetUtil.post_req(req_url,params).body)
    end

  end # End of OpenPlatformV1 class

end
