module MacroDeck
	# This code borrowed from RTurk.
	class TurkSigner
		def self.sign(secret_key, service, method, time)
			msg = "#{service}#{method}#{time}"
			return hmac_sha1(secret_key, msg)
		end

		private
			def self.hmac_sha1(key, s)
				ipad = [].fill(0x36, 0, 64)
				opad = [].fill(0x5C, 0, 64)
				key = key.unpack("C*")
				key += [].fill(0, 0, 64-key.length) if key.length < 64

				inner = []
				64.times { |i| inner.push(key[i] ^ ipad[i]) }
				inner += s.unpack("C*")

				outer = []
				64.times { |i| outer.push(key[i] ^ opad[i]) }
				outer = outer.pack("c*")
				outer += Digest::SHA1.digest(inner.pack("c*"))

				return Base64::encode64(Digest::SHA1.digest(outer)).chomp
			end
	end
end
