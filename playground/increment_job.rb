class IncrementJob
  def self.perform
    user = User.find_or_create_by(email: "b@b.com")
    user.increment!(:visits)
  end
end
