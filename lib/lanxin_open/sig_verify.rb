module SigVerify

	def sig_verify(time_str,nonce,token,signature)
  	time = time_str.to_i
  	time = time / 1000 if time_str.length >= 13
  	return false if (Time.now - Time.at(time)) > 120

    signature == sig_gen(time_str,nonce,token)
  end

  def sig_gen(time_str,nonce,token)
  	plain = [token,time_str,nonce].sort().join()
  	sig = Digest::SHA1.hexdigest(plain)
  end

end
