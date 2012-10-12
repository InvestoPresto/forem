module Forem
  class Subscription < ActiveRecord::Base
    belongs_to :topic
    belongs_to :subscriber, :class_name => Forem.user_class.to_s

    validates :subscriber_id, :presence => true

    attr_accessible :subscriber_id

    # alias :user_id :subscriber_id

    def user_id
      self.subscriber_id
    end

    def user
      self.subscriber
    end

    def send_notification(post_id)
      SubscriptionMailer.topic_reply(post_id, subscriber.id).deliver
    end
  end
end
