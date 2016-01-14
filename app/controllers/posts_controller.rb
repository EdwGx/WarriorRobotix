class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  skip_before_action :authenticate_admin!, only: [:index, :show]

  # GET /posts
  # GET /posts.json
  def index
    case params[:type]
    when "Event"
      post_scope = Event
    when "Poll"
      post_scope = Poll
    else
      post_scope = Post
    end
    if member_signed_in?
      if current_member.team_id.nil? || member_is_admin?
        post_scope = post_scope.where('"posts"."restriction" <= ?', max_restriction)
      else
        post_scope = post_scope.joins('LEFT JOIN "posts_teams" ON "posts_teams"."post_id" = "posts"."id"').where('"posts"."restriction" <= ? OR "posts_teams"."team_id" = ?', max_restriction, current_member.team_id)
      end
    else
      post_scope = post_scope.where(restriction: 0)
    end
    @posts = post_scope.order(created_at: :desc).page(params[:page]).per(10)
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
    if @post.restriction_value > max_restriction
      if member_signed_in?
        unless @post.team_ids.include?(current_member.team_id)
          raise Forbidden
        end
      else
        redirect_to signin_path(return_to_info)
      end
    end
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  # POST /posts.json
  def create
    @post=  Post.new(post_params)
    @post.author = current_member
    if @post.limited? && params[:teams].present?
      @post.team_ids = params[:teams].keys
    end

    respond_to do |format|
      if @post.save
        if @post.email_notification
          PostMailer.post_email(@post, true).deliver_later
        end
        format.html { try_redirect_back { redirect_to @post, notice: 'Post was successfully created.' } }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    respond_to do |format|
      if (params[:post][:restriction] == "limited" || (params[:post][:restriction].nil? && @post.limited?)) && params[:teams].present?
        @post.team_ids = params[:teams].keys
      end
      if @post.update(post_params)
        if @post.email_notification
          PostMailer.post_email(@post, false).deliver_later
        end
        format.html { try_redirect_back { redirect_to @post, notice: 'Post was successfully updated.' } }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_url, notice: 'Post was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :description, :restriction, :email_notification, :disabled)
  end
end
