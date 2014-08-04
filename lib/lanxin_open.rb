require "lanxin_open/version"
require "lanxin_open/sig_verify"
require "lanxin_open/openplatform"
require "json"

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

  def self.new_with_params(args)
    OpenPlatformV1.new(args)
  end

  def self.new
    OpenPlatformV1.new({})
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

end

LanxinOpen.config do
  parameter :host, :port
  parameter :use_new_json
end


