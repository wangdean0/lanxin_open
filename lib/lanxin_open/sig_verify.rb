module SigVerify

	def sig_verify(params)
  	time = params["timestamp"].to_i
  	time = time.to_i / 1000 if params["timestamp"].length >= 13
  	return false if (Time.now - Time.at(time)) > 120

  	plain = [Rails.application.config.data_token,params["timestamp"],params["nonce"]].sort().join()
  	sig = Digest::SHA1.hexdigest(plain)
  	sig == params["signature"]
  end

end
