module GuidestarClient
  class Adapter
    FIELD_MAPPING = { 
      "generalInformation" => {
        "orgName" => :name,
        "ein"     => :ein,
        "address" => {
          "addressLine1" => :address_line1,
          "addressLine2" => :address_line2,
          "addressLine3" => :address_line3,
          "city"         => :address_city,
          "state"        => :address_state,
          "zip"          => :address_zip
        },
        "contact" => {
          "prefix"    => :contact_prefix,
          "firstName" => :contact_first_name,
          "lastName"  => :contact_last_name,
          "title"     => :contact_title,
          "email"     => :contact_email,
          "phone"     => :contact_phone,
          "fax"       => :contact_fax
        },
        "executive" => {
          "prefix"    => :executive_prefix,
          "firstName" => :executive_first_name,
          "lastName"  => :executive_last_name,
          "title"     => :executive_title
        },
        "yearFounded"    => :year_founded,
        "rulingYear"     => :ruling_year,
        "assets"         => :assets,
        "income"         => :income,
        "ntees"          => [:ntees, :ntee_codes],
        "irsSubsection"  => :irs_subsection,
        "url"            => :url,
        "worldLocations" => :world_locations,
        "description"    => :description,
        "aka"            => :aka,
        "deductibility"  => :deductibility,
        "usaLocations"   => :usa_locations,
        "is501c3"        => [:yesno, :is_501c3],
      },
      "missionAndPrograms" => {
        "mission"  => :mission,
        "programs" => :programs
      },
#      "charityCheck" => {
#        "pub78Verified" => [:yesno, :is_pub78_verified],
#        "is509a3"       => [:yesno, :is_509a3],
#        "ofacOrg"       => [:yesno, :is_ofac_org],
#        "pub78Date"     => [:date, :pub78_date],
#        "irbDate"       => :irb_date,
#      }
    }
    
    attr_reader :client, :query_options
    
    def initialize(client, query_options)
      @client = client
      @query_options = query_options
    end
    
    def each_record
      client.query_each(query_options) do |organization|
        yield charity_data_from_xml(organization)
      end
    end
    
    def timestamp_column_name
      :guidestar_updated_at
    end
        
    def charity_data_from_xml(root, mapping = nil)
      mapping ||= FIELD_MAPPING
      data = {}
      
      mapping.each do |key, value|
        node = root.css(key)
        
        case value
        when Hash
          data.update(charity_data_from_xml(node, value))
        when Array
          data[value.second] = field_from_xml(node, value.first)
        when String, Symbol
          data[value] = field_from_xml(node, :string)
        end
      end
      
      data.reject { |key, value| value.blank? }
    end
    
    def field_from_xml(node, conversion)
      return if node.text.blank?
      
      case conversion
      when :string
        node.text
      when :yesno
        node.text == "yes"
      when :ntees
        node.css("ntee code").collect(&:text)
      end
    end
    
    def self.find_from_node(node)
      Charity.find_by_ein(node.css("generalInformation ein").text)
    end
  end
end
