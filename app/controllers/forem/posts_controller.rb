module Forem
  class PostsController < Forem::ApplicationController
    before_filter :authenticate_forem_user
    before_filter :find_topic
    before_filter :block_spammers, :only => [:new, :create]

    def new
      authorize! :reply, @topic
      @post = @topic.posts.build
      redirect_to forum_topic_path(@topic.forum, @topic)
    end

    def create
      authorize! :reply, @topic
      if @topic.locked?
        flash.alert = t("forem.post.not_created_topic_locked")
        redirect_to [@topic.forum, @topic] and return
      end
      @post = @topic.posts.build(params[:post])
      @post.user = forem_user
      if @post.save
        flash[:notice] = t("forem.post.created")
        redirect_to forum_topic_url(@topic.forum, @topic, :page => last_page)
      else
        params[:reply_to_id] = params[:post][:reply_to_id]
        flash.now.alert = t("forem.post.not_created")
        render :action => "new"
      end
    end

    def edit
      authorize! :edit_post, @topic.forum
      @post = Post.find(params[:id])
    end

    def update
      authorize! :edit_post, @topic.forum
      @post = Post.find(params[:id])
      if @post.owner_or_admin?(forem_user) and @post.update_attributes(params[:post])
        redirect_to [@topic.forum, @topic], :notice => t('edited', :scope => 'forem.post')
      else
        flash.now.alert = t("forem.post.not_edited")
        render :action => "edit"
      end
    end

    def destroy
      @post = @topic.posts.find(params[:id])
      if @post.owner_or_admin?(forem_user)
        @post.destroy
        if @post.topic.posts.count == 0
          @post.topic.destroy
          flash[:notice] = t("forem.post.deleted_with_topic")
          redirect_to [@topic.forum]
        else
          flash[:notice] = t("forem.post.deleted")
          redirect_to [@topic.forum, @topic]
        end
      else
        flash[:alert] = t("forem.post.cannot_delete")
        redirect_to [@topic.forum, @topic]
      end

    end

    def vote
      if params[:type] == 'up'
        value = 1
        scope = :positive
      else
        value =  -1
        scope = :negative
      end
      @post = Post.find(params[:id])

      unless @post.evaluators_for(:votes, :negative).include?(forem_user) || @post.evaluators_for(:votes, :positive).include?(forem_user)
        @post.add_or_update_evaluation(:votes, value, forem_user, scope)
      end

      respond_to do |format|
          format.js   { render :layout=>false }
          format.html { redirect_to forum_topic_path(@topic.forum, @topic), notice: t("forem.post.voted") }
      end
    end

    def spam
      @post = Post.find(params[:id])
      @post.add_spam_vote_and_check(forem_user)
      redirect_to :back, notice: t("forem.topic.spam_detected")
    end


    private

    def find_topic
      @topic = Forem::Topic.find(params[:topic_id])
    end

    def block_spammers
      if forem_user.forem_state == "spam"
        flash[:alert] = t('forem.general.flagged_for_spam') + ' ' + t('forem.general.cannot_create_post')
        redirect_to :back
      end
    end

    def last_page
      (@topic.posts.count.to_f / Forem.per_page.to_f).ceil
    end
  end
end
