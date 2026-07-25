class NotifierMailer < ActionMailer::Base
  def welcome
    mail(from: "noreply@example.test", to: "c@c.com", subject: "welcome", body: "hi")
  end
end

class MailerJob
  def self.perform
    User.find_or_create_by(email: "c@c.com")
    NotifierMailer.welcome.deliver_now
  end
end

class HappyMailerJob
  def self.perform
    user = User.find_or_create_by(email: "e@e.com")
    return if user.notified?

    NotifierMailer.welcome.deliver_now
    user.update!(notified: true)
  end
end
