require 'spec_helper'
require 'guidestar_client'
require 'guidestar_client/fake_guidestar'

describe GuidestarClient::Client do
  def client
    @client ||= begin
      c = GuidestarClient::Client.new
      c.login = "testuser"
      c.password = "testpassword"
      c
    end
  end
  
  before do
    FakeGuidestar.setup_stubs!
  end
  
  describe "an invalid login" do
    before do
      @invalid_client = client
      @invalid_client.password = "invalid"
    end
    
    it "should raise an error" do
      lambda { @invalid_client.query!(:ein => "01-0000001") }.should raise_error
    end
  end
  
  describe "an EIN query" do
    it "should get back a single charity" do
      response = client.query!(:ein => "01-0000001")
      response.size.should == 1
      response.first.xpath("generalInformation/ein").text.should == "01-0000001"
    end
  end
  
  describe "a ZIP query" do
    it "should get back multiple charities" do
      response = client.query!(:zip => "10706")
      response.size.should > 1
      response.each do |charity|
        charity.xpath("generalInformation/address/zip").text.should == "10706"
      end
    end
  end
  
  describe "a big query" do
    it "should default to 100 charities" do
      response = client.query!(:zip => "10001")
      response.size.should == 100
    end
    
    describe "with a size limit" do
      it "should return the limited number of charities" do
        response = client.query!(:zip => "10001", :pageSize => 10)
        response.size.should == 10
      end
    end
    
    describe "with query_each" do
      it "should repeatedly query until done" do
        n = 0
        client.query_each(:zip => "10001") do |charity|
          n += 1
          charity.xpath("generalInformation/orgName").text.should == "NYC Charity #{n}"
        end
        n.should == 500
      end
    end
  end
end
