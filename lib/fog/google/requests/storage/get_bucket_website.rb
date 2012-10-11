module Fog
  module Storage
    class Google
      class Real

        require 'fog/google/parsers/storage/get_bucket_website'

        # Get bucket website for an Google Storage bucket
        #
        # ==== Parameters
        # * bucket_name<~String> - name of bucket to get website for
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'WebsiteConfiguration'<~Hash>
        #       * 'MainPageSuffix'<~String> - Main page for the bucket
        #       * 'NotFoundPage'<~String> - Error page for bucket
        #
        def get_bucket_website(bucket_name)
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          request({
            :expects    => 200,
            :headers    => {},
            :host       => "#{bucket_name}.#{@host}",
            :idempotent => true,
            :method     => 'GET',
            :parser     => Fog::Parsers::Storage::Google::GetBucketWebsite.new,
            :query      => {'websiteConfig' => nil}
          })
        end

      end

      class Mock

        # def get_bucket_website(bucket_name)
        #   response = Excon::Response.new
        #   if acl = self.data[:acls][:bucket][bucket_name]
        #     response.status = 200
        #     response.body = acl
        #   else
        #     response.status = 404
        #     raise(Excon::Errors.status_error({:expects => 200}, response))
        #   end
        #   response
        # end

      end
    end
  end
end
