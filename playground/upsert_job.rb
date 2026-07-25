class UpsertJob
  def self.perform
    user = User.find_or_create_by(email: "g@g.com")
    user.touch # always bumps updated_at, even though no business data changes
  end
end
