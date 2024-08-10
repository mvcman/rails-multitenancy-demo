require "test_helper"

class AccountUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_user = account_users(:one)

    @user = users(:one)
    @user2 = users(:two)
    @account = accounts(:one)
    sign_in @user
  end

  test "should get index" do
    get account_account_users_url(@account)
    assert_response :success
    assert_match @account_user.user.email, response.body
  end

  test "should get new" do
    get new_account_account_user_url(@account)
    assert_response :success
  end

  test "should create account_user" do
    email = "julia@superails.com"

    # nil email
    assert_no_difference("User.count") do
      assert_no_difference("AccountUser.count") do
        post account_account_users_url(@account), params: { invite_account_user_form: { email: nil } }
      end
    end
    assert_response :unprocessable_entity

    # invalid email
    assert_no_difference("User.count") do
      assert_no_difference("AccountUser.count") do
        post account_account_users_url(@account), params: { invite_account_user_form: { email: "foo" } }
      end
    end
    assert_response :unprocessable_entity

    # success
    assert_difference("User.count") do
      assert_difference("AccountUser.count") do
        post account_account_users_url(@account), params: { invite_account_user_form: { email: } }
      end
    end

    assert_redirected_to account_account_users_url
    assert @account.users.find_by(email:)

    # when user is already a member
    assert_no_difference("User.count") do
      assert_no_difference("AccountUser.count") do
        post account_account_users_url(@account), params: { invite_account_user_form: { email: } }
      end
    end
    assert_response :unprocessable_entity
  end

  test "#edit" do
    # admin can not edit himself
    get edit_account_account_user_url(@account, @account_user)
    assert_response :redirect

    # admin can edit other account user
    @account.users << @user2
    second_account_user = @account.account_users.find_by(user: @user2)
    get edit_account_account_user_url(@account, second_account_user)
    assert_response :success

    # only admin can edit account user
    sign_in @user2
    get edit_account_account_user_url(@account, @account_user)
    assert_response :redirect
  end

  test "#update" do
    # admin can not update himself
    patch account_account_user_url(@account, @account_user), params: { account_user: { role: "member" } }
    assert_redirected_to account_account_users_url
    assert @account_user.reload.admin?

    # admin can update other account user
    @account.users << @user2
    second_account_user = @account.account_users.find_by(user: @user2)
    patch account_account_user_url(@account, second_account_user), params: { account_user: { role: "admin" } }
    assert_redirected_to account_account_users_url
    assert second_account_user.reload.admin?

    # only admin can update account user
    first_account_user = @account.account_users.find_by(user: @user)
    first_account_user.member!
    patch account_account_user_url(@account, second_account_user), params: { account_user: { role: "member" } }
    assert_redirected_to account_url(@account)
    assert second_account_user.reload.admin?
  end

  test "#destroy" do
    # does not destroy only account user
    assert_difference("AccountUser.count", 0) do
      delete account_account_user_url(@account, @account_user)
    end
    assert_redirected_to account_account_users_url

    # destroys another account user
    @account.users << @user2
    second_account_user = @account.account_users.find_by(user: @user2)
    assert_difference("AccountUser.count", -1) do
      delete account_account_user_url(@account, second_account_user)
    end

    # does not destroy only admin account user
    @account.users << @user2
    second_account_user = @account.account_users.find_by(user: @user2)
    assert_difference("AccountUser.count", 0) do
      delete account_account_user_url(@account, @account_user)
    end

    # destroys admin if there is another admin
    second_account_user.admin!
    assert_difference("AccountUser.count", -1) do
      delete account_account_user_url(@account, @account_user)
    end
  end
end
