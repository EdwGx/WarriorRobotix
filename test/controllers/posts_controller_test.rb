require 'test_helper'

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:everyone)
    @admin = members(:edward)
    post "/signin", params: { identifier: @admin.student_number, password: '123456' }
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get new" do
    session[:member_id] = members(:edward).id
    get new_post_url
    assert_response :success
  end

  test "should create post" do
    session[:member_id] = members(:edward).id
    assert_difference('Post.count') do
      post posts_url, params: { post: { description: @post.description, restriction: @post.restriction, title: @post.title } }
    end

    assert_redirected_to post_path(Post.last)
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should get edit" do
    session[:member_id] = members(:edward).id
    get edit_post_url(@post)
    assert_response :success
  end

  test "should update post" do
    session[:member_id] = members(:edward).id
    patch post_url(@post), params: { post: { description: @post.description, restriction: @post.restriction, title: @post.title } }
    assert_redirected_to post_path(@post)
  end

  test "should destroy post" do
    session[:member_id] = members(:edward).id
    assert_difference('Post.count', -1) do
      delete post_url(@post)
    end

    assert_redirected_to posts_path
  end
end
