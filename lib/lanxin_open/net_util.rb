require 'addressable/uri'
require 'net/https'
require 'uri'

module LanxinOpen

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

end
