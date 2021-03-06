require 'rack/test'
require 'spec_helper'
require 'routers/admin'

describe Routers::Admin do
  include Rack::Test::Methods

  let(:browser) { Rack::Test::Session.new(Rack::MockSession.new(app)) }
  let(:admin_key) { 'the-admin-key' }

  before(:each) { ChiScore::Repository.set_strategy(ChiScore::RedisStrategy) }

  def app
    Routers::Admin
  end

  it "if admin, saves race start time and redirects after request" do
    ChiScore::Repository.should_receive(:save_race_start)
    expect(ChiScore::Auth).to receive(:admin_key) { admin_key }
    browser.get "/start-race", {}, 'rack.session' => { "admin" => admin_key }
    browser.last_response.status.should == 302
  end

  it "if not admin, does not save race start time and redirects after request" do
    ChiScore::Repository.should_not_receive(:save_race_start)
    expect(ChiScore::Auth).to receive(:admin_key) { admin_key }
    browser.get "/", {}, 'rack.session' => { "admin" => "" }
    browser.last_response.status.should == 302
  end
end
