module Fog
  module Storage
    class AWS
      class Real

        require 'fog/aws/parsers/storage/cors_config'

        # Get CORS configuration for an S3 bucket
        #
        # ==== Parameters
        # * bucket_name<~String> - name of bucket to get notification for
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'CORSConfiguration'<~Array>: (will be empty if notification is disabled)
        #       * 'CORSRule'<~Hash>:
        #         * 'AllowedHeader'<~String> - Specifies which headers are allowed in pre-flight OPTIONS request throught the Access-Control-Request-Headers header.
        #         * 'AllowedMethod'<~String> - Identifies an HTTP method that the domain/origin specified in the rule is allowed to execute.
        #         * 'AllowedOrigin'<~String> - One or more response headers that you want users to be able to access from their applications.
        #         * 'ExposeHeader'<~String> - One or more headers in the response that you want customers to be able to access from their applications.
        #         * 'ID'<~String> - An optional unique identifier for the rule.
        #         * 'MaxAgeSeconds'<~Integer> - The time in seconds that your browser is to cache the preflight response for the specified resource.

        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html

        def get_bucket_cors(bucket_name)
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          request({
            :expects    => 200,
            :headers    => {},
            :host       => "#{bucket_name}.#{@host}",
            :idempotent => true,
            :method     => 'GET',
            :parser     => Fog::Parsers::Storage::AWS::CORSConfig.new,
            :query      => {'cors' => nil}
          })
        end

      end
    end
  end
end
