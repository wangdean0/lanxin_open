require "lanxin_open/version"
require 'uri'
require "json"
require 'addressable/uri'
require 'net/https'

module LanxinOpen
  extend self

  def self.parameter(*names)
    names.each do |name|
      attr_accessor name
      # For each given symbol we generate accessor method that sets option's
      # value being called with an argument, or returns option's current value
      # when called without arguments
      define_method name do |*values|
        value = values.first
        value ? self.send("#{name}=", value) : instance_variable_get("@#{name}")
      end
    end
  end

  def self.config(&block)
    instance_eval &block
  end

  def self.new
    OpenPlatformV1.new
  end

  def self.dean_hash2xml(p_hash)
    # return nil if (not p_hash) or p_hash.length <= 0
    no_cdata_key = ["CreateTime","MsgId"]
    line_break = "" #"\n"
    xml_str = "<xml>#{line_break}"
    p_hash.each do |k,v|
      if no_cdata_key.include?(k)
        xml_str += "<#{k}>#{v}</#{k}>#{line_break}"
      else
        xml_str += "<#{k}><![CDATA[#{v}]]></#{k}>#{line_break}"
      end
    end
    xml_str += "</xml>"
  end

  def self.hash_to_xml(p_hash)
    # return nil if (not p_hash) or p_hash.length <= 0
    return dean_hash2xml(p_hash)
  end

  def self.parse_callback_xml(msgcontent)
    begin
      hash = Hash.from_xml(msgcontent)
      xml_node = hash["xml"]
      return xml_node
    rescue
    end
  end

  class NetUtil
    def self.get_req(url)
      return nil if not url
      #Rails.logger.info("get_req request url:#{url}")
      uri = URI(url)

      https = Net::HTTP.new(uri.host, uri.port)
      #just for now.FIXME
      if uri.scheme == 'https'
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response = https.get(uri.request_uri)
    end

    def self.dict2urlparam(params)
      return if not params
      uri = Addressable::URI.new
      uri.query_values = params
      uri.query
    end

    def self.force_encode(params,encoding_name)
      params.each do |k,v|
        if v.class == String #and v.encoding.name == "UTF-8"
          begin
            v_gbk = v.encode(encoding_name)
            params[k] = v_gbk
          rescue
          end
        end
      end
      return params
    end

    def self.post_req(url,params)
      return if not url
      uri = URI.parse(url)

      need_uri_encode = false
      if need_uri_encode
        params.each do |k,v|
          params[k] = URI.encode(v)
        end
      end

      https = Net::HTTP.new(uri.host,uri.port)
      if uri.scheme == 'https'
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data(params)
      response = https.request(req)
    end
  end

  module Platform
    attr_accessor :skey

    def dump_config
      puts "test_config #{LanxinOpen.host}, #{LanxinOpen.port}, #{LanxinOpen.use_new_json}"
    end

    def host_with_port
      "#{LanxinOpen.host}:#{LanxinOpen.port}"
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
      return gbk
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
      base_json["text"] = text_json if LanxinOpen.use_new_json
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
      return body
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
      # base_json["news"] = news_json if LanxinOpen.use_new_json
      body = kehu_msg(base_json,from_user)
      return body
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
        "publicno" => publicno
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

  end

end

LanxinOpen.config do
  parameter :host, :port
  parameter :use_new_json
end


