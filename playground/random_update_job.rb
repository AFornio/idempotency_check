require "securerandom"

class RandomUpdateJob
  def self.perform
    user = User.find_or_create_by(email: "o@o.com")
    user.update!(visits: SecureRandom.hex(4).to_i(16))
  end
end
