require 'rack'
require 'webmock'
require 'active_support/core_ext'

class FakeGuidestar
  extend WebMock::API
  
  @@charities = []
  1.upto(5) do |i|
    @@charities << {
      "generalInformation" => {
        "orgName" => "Charity #{i} of Hastings",
        "ein" => "01-#{sprintf("%07d", i)}",
        "address" => {
          "addressLine1" => "#{i} Main St.",
          "city" => "Hastings-on-Hudson",
          "state" => "NY",
          "zip" => "10706"
        }
      }
    }
  end
  1.upto(500) do |i|
    @@charities << {
      "generalInformation" => {
        "orgName" => "NYC Charity #{i}",
        "ein" => "02-#{sprintf("%07d", i)}",
        "address" => {
          "addressLine1" => "#{i} Broadway",
          "city" => "New York",
          "state" => "NY",
          "zip" => "10001"
        }
      }
    }
  end
  
  @@login = "testuser"
  @@password = "testpassword"
  
  def self.charities
    @@charities
  end

  def self.charities=(charities)
    @@charities = charities
  end

  def self.login
    @@login
  end

  def self.login=(login)
    @@login = login
  end

  def self.password
    @@password
  end

  def self.password=(password)
    @@password = password
  end

  def self.client
    @@client
  end

  def self.client=(client)
    @@client = client
  end
  
  def self.call(env)
    request = Rack::Request.new(env)
    body = Nokogiri::XML.parse(request.body)
    xml_input = body.xpath("/env:Envelope/env:Body/gs:GuideStarDetail/gs:xmlInput",
      "env" => "http://schemas.xmlsoap.org/soap/envelope/",
      "gs" => "https://gsservices.guidestar.org")
    query = Nokogiri::XML.parse(xml_input.text).xpath("/query")
    
    login, password = %w{login password}.collect { |q| query.xpath(q).text }
    unless login == @@login && password == @@password
      return [403, {}, ["Access denied - got #{login}/#{password}, expected #{@@login}/#{@@password}"]]
    end
    
    page_size, offset = %w{pageSize offset}.collect { |q| query.xpath(q).text }
    unless page_size && offset
      return [401, {}, ["Must specify pageSize and offset"]]
    end
    page_size = page_size.to_i
    offset = offset.to_i
    
    ein, zip = %w{ein zip}.collect { |q| query.xpath(q).text }
    charities = if ein.present?
      @@charities.select { |charity| charity["generalInformation"]["ein"] == ein }
    elsif zip.present?
      @@charities.select { |charity| charity["generalInformation"]["address"]["zip"] == zip }
    else
      @@charities
    end
    
    charities.slice!(0, offset.to_i) if offset > 0
    charities = charities.slice(0, page_size) if page_size < charities.size
    
    result = Gyoku.xml(
      :root => {
        :organizations => charities.collect { |c| { :organization => c } }
      }
    )
    
    body = Gyoku.xml(
      "soap:Envelope" => {
        "soap:Body" => {
          :GuideStarDetailResponse => {
            :GuideStarDetailResult => result
          }
        }
      },
      :attributes! => { "soap:Envelope" => { "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/" } }
    )
    
    [200, {}, [body]]
  end
  
  def self.setup_stubs!
    stub_request(:post, %r{^https://gsservices.guidestar.org/GuideStar_SearchService/}).to_rack(FakeGuidestar)
    
    wsdl_file = File.expand_path("#{__FILE__}/../guidestar.wsdl")
    stub_request(:get, "https://gsservices.guidestar.org/GuideStar_SearchService/SearchService.asmx?WSDL").
      to_return(:body => File.new(wsdl_file), :status => 200)
  end
  
  def self.setup_client!
    Tipjar::Application.guidestar_client.login = self.login
    Tipjar::Application.guidestar_client.password = self.password
  end
end
