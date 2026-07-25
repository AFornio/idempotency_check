require "net/http"

# Fakes the network layer so this playground never makes a real outbound
# HTTP call. HttpTracker wraps whatever #request is defined at tracking
# time, so it still counts calls correctly through this fake.
class Net::HTTP
  def request(*, **)
    Net::HTTPResponse.new("1.1", "200", "OK")
  end
end

class ApiJob
  def self.perform
    user = User.find_or_create_by(email: "c@c.com")
    Net::HTTP.new("example.test", 80).request(Net::HTTP::Get.new("/notify"))
    user
  end
end
