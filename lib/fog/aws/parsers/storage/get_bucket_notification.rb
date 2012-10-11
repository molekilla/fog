module Fog
  module Parsers
    module Storage
      module AWS

        class GetBucketNotification < Fog::Parsers::Base

          def reset
            @response = { 'NotificationConfiguration' => {} }
          end

          def end_element(name)
            case name
            when 'Topic', 'Event'
              @response['NotificationConfiguration'][name] = value
            end
          end

        end

      end
    end
  end
end
