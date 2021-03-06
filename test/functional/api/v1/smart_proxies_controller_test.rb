require 'test_helper'

class Api::V1::SmartProxiesControllerTest < ActionController::TestCase

  valid_attrs = { :name => 'master02', :url => 'http://server:8443' }

  test "should get index" do
    get :index, { }
    assert_response :success
    assert_not_nil assigns(:smart_proxies)
    smart_proxies = ActiveSupport::JSON.decode(@response.body)
    assert !smart_proxies.empty?
  end

  test "should get index filtered by type" do
    as_user :admin do
      get :index, { :type => 'tftp' }
    end
    assert_response :success
    assert_not_nil assigns(:smart_proxies)
    smart_proxies = ActiveSupport::JSON.decode(@response.body)
    assert !smart_proxies.empty?

    returned_proxy_ids = smart_proxies.map { |p| p["smart_proxy"]["id"] }
    expected_proxy_ids = SmartProxy.tftp_proxies.map { |p| p.id }
    assert returned_proxy_ids == expected_proxy_ids
  end

  test "index should fail with invalid type filter" do
    as_user :admin do
      get :index, { :type => 'unknown_type' }
    end
    assert_response :error
  end

  test "should show individual record" do
    get :show, { :id => smart_proxies(:one).to_param }
    assert_response :success
    show_response = ActiveSupport::JSON.decode(@response.body)
    assert !show_response.empty?
  end

  test "should create smart_proxy" do
    assert_difference('SmartProxy.count') do
      post :create, { :smart_proxy => valid_attrs }
    end
    assert_response :success
  end

  test "should update smart_proxy" do
    put :update, { :id => smart_proxies(:one).to_param, :smart_proxy => { } }
    assert_response :success
  end

  test "should destroy smart_proxy" do
    assert_difference('SmartProxy.count', -1) do
      delete :destroy, { :id => smart_proxies(:four).to_param }
    end
    assert_response :success
  end

  # Pending - failure on .permission_failed?
  # test "should not destroy smart_proxy that is in use" do
  #   as_user :admin do
  #     assert_difference('SmartProxy.count', 0) do
  #       delete :destroy, {:id => smart_proxies(:one).to_param}
  #     end
  #   end
  #   assert_response :unprocessable_entity
  # end

  test "should refresh smart proxy features" do
    proxy = smart_proxies(:one)
    SmartProxy.any_instance.stubs(:associate_features).returns(true)
    post :refresh, {:id => proxy}
    assert_response :success
  end

  test "should return errors during smart proxy refresh" do
    proxy = smart_proxies(:one)
    errors = ActiveModel::Errors.new(Host::Managed.new)
    errors.add :base, "Unable to communicate with the proxy: it's down"
    SmartProxy.any_instance.stubs(:errors).returns(errors)
    SmartProxy.any_instance.stubs(:associate_features).returns(true)
    post :refresh, {:id => proxy}, set_session_user
    assert_response :unprocessable_entity
  end

end
