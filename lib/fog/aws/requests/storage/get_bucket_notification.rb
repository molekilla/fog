module Fog
  module Storage
    class AWS
      class Real

        require 'fog/aws/parsers/storage/get_bucket_notification'

        # Get notification for an S3 bucket
        #
        # ==== Parameters
        # * bucket_name<~String> - name of bucket to get notification for
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'NotificationConfiguration'<~Hash>: (will be empty if notification is disabled)
        #       * 'TopicConfiguration'<~Hash>:
        #         * 'Topic'<~String> - Amazon SNS topic to which Amazon S3 will publish a message to report the specified events for the bucket.
        #         * 'Event'<~String> - Bucket event to send notifications for

        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGetNotification.html

        def get_bucket_notification(bucket_name)
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          request({
            :expects    => 200,
            :headers    => {},
            :host       => "#{bucket_name}.#{@host}",
            :idempotent => true,
            :method     => 'GET',
            :parser     => Fog::Parsers::Storage::AWS::GetBucketNotification.new,
            :query      => {'notification' => nil}
          })
        end

      end
    end
  end
end
