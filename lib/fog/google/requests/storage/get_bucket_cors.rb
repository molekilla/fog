module Fog
  module Storage
    class Google
      class Real

        require 'fog/google/parsers/storage/cors_config'

        # Get bucket CORS for a Google Storage bucket
        #
        # ==== Parameters
        # * bucket_name<~String> - name of bucket to get website for
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'CorsConfig'<~Hash>  
        #     * 'Cors'<~Hash>
        #       * 'Origins'<~Hash>
        #         * 'Origin'<~String> - The allowed cross origin resource sharing assigned to the bucket.
        #       * 'Methods'<~Hash> - Container for one or more HTTP method elements
        #         * 'Method'<~String> - Either GET, HEAD, PUT, POST or DELETE
        #       * 'ResponseHeaders'<~Hash>
        #         * 'ResponseHeader'<~String> - A response header that the use agent is permitted to share across origins.
        #       * 'MaxAgeSec'<~Integer> - Maximum age in seconds
        #
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
            :parser     => Fog::Parsers::Storage::Google::CORSConfig.new,
            :query      => {'cors' => nil}
          })
        end

      end

      class Mock

        # def get_bucket_cors(bucket_name)
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
