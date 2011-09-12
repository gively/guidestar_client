require 'savon'

module GuidestarClient
  QUERY_PARAMS = [:keyword, :city, :state, :zip, :zipradius, :ein, :orgName, 
        :category, :subCategory, :nteeCode]

  class Client
    attr_reader :soap_client
    attr_accessor :login, :password
    
    def initialize
      @soap_client = Savon::Client.new do
        wsdl.document = "https://gsservices.guidestar.org/GuideStar_SearchService/SearchService.asmx?WSDL"
      end
    end
        
    def search_query_xml(parameters = {})
      # GuideStar is very picky about field order in the query.  We have to make sure to
      # specify fields in the right order.
      order = [:version, :login, :password, :pageSize, :offset]
      
      GuidestarClient::QUERY_PARAMS.each do |field|
        order << field.to_sym if parameters[field.to_sym]
      end
      
      Gyoku.xml(
        :query => {
          :version => "1.0",
          :login => @login,
          :password => @password,
          :pageSize => 100,
          :offset => 0,
          :order! => order
        }.merge(parameters)
      )
    end
    
    def query!(parameters = {})
      response = @soap_client.request(:guide_star_detail) do
        soap.body = { :xmlInput => search_query_xml(parameters) }
      end
      
      result = Nokogiri::XML::Document.parse(
        response[:guide_star_detail_response][:guide_star_detail_result]
      )
      
      result.xpath("/root/organizations/organization").to_a
    end
    
    def query_each(parameters = {})
      offset = 0
      limit = parameters.delete(:limit) || 1000
      parameters[:pageSize] ||= 100
      
      while true
        break if (limit && offset >= limit)
      
        page = query!(parameters.merge(:offset => offset))
        break if page.size == 0
        
        page.each do |organization|
          yield organization
        end
        
        offset += parameters[:pageSize]
      end
    end
  end
end
