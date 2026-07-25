class BadJob
  def self.perform
    User.create!(email: "a@a.com")
  end
end
