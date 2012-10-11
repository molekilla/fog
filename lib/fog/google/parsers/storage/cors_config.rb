module Fog
  module Parsers
    module Storage
      module Google

        class CORSConfig < Fog::Parsers::Base

          def reset
            @grant = { 'Grantee' => {} }
            @response = { 'CorsConfig' => {} }
          end

          def end_element(name)
            case name
            when 'Cors'
              @response[name] = {}
            when 'Origins'
              @response['Cors'][name] = value
            when 'Methods'
              @response['Cors'][name] = []
            when 'Method'
              @response['Cors']['Methods'] << value
            when 'ResponseHeaders'
              @response['Cors'][name] = value
            end
          end

        end

      end
    end
  end
end
