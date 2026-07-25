class HappyJob
  def self.perform
    User.find_or_create_by(email: "a@a.com")
  end
end
