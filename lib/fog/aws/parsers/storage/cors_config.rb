module Fog
  module Parsers
    module Storage
      module AWS

        class CORSConfig < Fog::Parsers::Base

          def reset
            @rule = { 'CORSRule' => {} }
            @response = { 'CORSConfiguration' => [] }
          end

          def end_element(name)
            case name
            when 'AllowedHeader', 'AllowedMethod', 'AllowedOrigin', 'ExposeHeader', 'ID', 'MaxAgeSeconds'
              @rule['CORSRule'][name] = value
            when 'CORSRule'
              @response['CORSConfiguration'] << @rule
              @rule = { 'CORSRule' => {} }
            end
          end

        end

      end
    end
  end
end
