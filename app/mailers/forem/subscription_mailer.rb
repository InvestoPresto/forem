module Forem
  class SubscriptionMailer < ActionMailer::Base
		# TODO: Make this configurable upon installation
    default from: "from@example.com"

    def topic_reply post_id
			# only pass id to make it easier to send emails using resque
			@post = Post.find(post_id)
		end
  end
end