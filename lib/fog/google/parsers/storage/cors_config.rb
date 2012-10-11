module Fog
  module Parsers
    module Storage
      module Google

        class CORSConfig < Fog::Parsers::Base

          def reset
            @response = { 'CorsConfig' => {} }
          end

          def end_element(name)
            case name
            when 'Cors'
              @response['CorsConfig'][name] = {}
            when 'Origins'
              @response['CorsConfig']['Cors'][name] = []
            when 'Origin'
              @response['CorsConfig']['Cors']['Origins'] << { 'Origin' => value }
            when 'Methods'
              @response['CorsConfig']['Cors'][name] = []
            when 'Method'
              @response['CorsConfig']['Cors']['Methods'] << { 'Method' => value }
            when 'ResponseHeaders'
              @response['CorsConfig']['Cors'][name] = []
            when 'ResponseHeader'
              @response['CorsConfig']['Cors']['ResponseHeaders'] << { 'ResponseHeader' => value }
            end
          end

        end

      end
    end
  end
end
