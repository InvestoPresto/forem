require 'friendly_id'

module Forem
  class Forum < ActiveRecord::Base
    include Forem::Concerns::Viewable

    extend FriendlyId

    friendly_id :title, :use => :slugged

    belongs_to :category

    has_many :topics,     :dependent => :destroy do
      def find(param)
        if param.friendly_id?
          find_by_slug param
        else
          find param
        end
      end
    end

    has_many :posts,      :through => :topics, :dependent => :destroy
    has_many :moderators, :through => :moderator_groups, :source => :group
    has_many :moderator_groups

    validates :category, :title, :description, :presence => true

    attr_accessible :category_id, :title, :description, :moderator_ids

    def self.find(param)
      if param.friendly_id?
        find_by_slug param
      else
        find param
      end
    end

    def last_post_for(forem_user)
      if forem_user && (forem_user.forem_admin? || moderator?(forem_user))
        posts.last
      else
        last_visible_post(forem_user)
      end
    end

    def last_visible_post(forem_user)
      posts.approved_or_pending_review_for(forem_user).last
    end

    def moderator?(user)
      user && (user.forem_group_ids & moderator_ids).any?
    end
  end
end
