module Fog
  module Parsers
    module Storage
      module Google

        class GetBucketWebsite < Fog::Parsers::Base

          def reset
            @response = { 'WebsiteConfiguration' => {} }
          end

          def end_element(name)
            case name
            when 'MainPageSuffix', 'NotFoundPage'
              @response['WebsiteConfiguration'][name] = value
            end
          end

        end

      end
    end
  end
end
