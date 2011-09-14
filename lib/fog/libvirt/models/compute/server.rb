require 'fog/core/model'
require 'fog/libvirt/models/compute/util'
require 'net/ssh/proxy/command'
require 'rexml/document'
require 'erb'
require 'securerandom'


module Fog
  module Compute
    class Libvirt

      class Server < Fog::Model

        include Fog::Compute::LibvirtUtil

        identity :id, :aliases => 'uuid'
        attribute :xml

        attribute :cpus
        attribute :cputime
        attribute :os_type
        attribute :memory_size
        attribute :max_memory_size

        attribute :name
        attribute :arch
        attribute :persistent
        attribute :domain_type
        attribute :uuid
        attribute :autostart

        attribute :state

        # The following attributes are only needed when creating a new vm
        attr_accessor :iso_dir, :iso_file
        attr_accessor :network_interface_type ,:network_nat_network, :network_bridge_name
        attr_accessor :volume_format_type, :volume_allocation,:volume_capacity, :volume_name, :volume_pool_name, :volume_template_name, :volume_path

        attr_accessor :password
        attr_writer   :private_key, :private_key_path, :public_key, :public_key_path, :username

        # Can be created by passing in :xml => "<xml to create domain/server>"
        # or by providing :template_options => {
        #                :name => "", :cpus => 1, :memory_size => 256 , :volume_template
        #   :}
        #
        # @returns server/domain created
        def initialize(attributes={} )

          self.xml  ||= nil unless attributes[:xml]
          self.persistent ||=true unless attributes[:persistent]
          self.cpus ||=1 unless attributes[:cpus]
          self.memory_size ||=256 *1024 unless attributes[:memory_size]
          self.name ||="fog-#{SecureRandom.random_number*10E14.to_i.round}" unless attributes[:name]

          self.os_type ||="hvm" unless attributes[:os_type]
          self.arch ||="x86_64" unless attributes[:arch]

          self.domain_type ||="kvm" unless attributes[:domain_type]

          self.iso_file ||=nil unless attributes[:iso_file]
          self.iso_dir ||="/var/lib/libvirt/images" unless attributes[:iso_dir]

          self.volume_format_type ||=nil unless attributes[:volume_format_type]
          self.volume_capacity ||=nil unless attributes[:volume_capacity]
          self.volume_allocation ||=nil unless attributes[:volume_allocation]

          self.volume_name ||=nil unless attributes[:volume_name]
          self.volume_pool_name ||=nil unless attributes[:volume_pool_name]
          self.volume_template_name ||=nil unless attributes[:volume_template_name]

          self.network_interface_type ||="nat" unless attributes[:network_interface_type]
          self.network_nat_network ||="default" unless attributes[:network_nat_network]
          self.network_bridge_name ||="br0" unless attributes[:network_bridge_name]

          super
        end

        def save

          raise Fog::Errors::Error.new('Resaving an existing server may create a duplicate') if uuid

          validate_template_options

          xml=xml_from_template if xml.nil?

          create_or_clone_volume

          xml=xml_from_template

          # We either now have xml provided by the user or generated by the template
          begin
            if !xml.nil?
              domain=nil
              if self.persistent
                domain=connection.raw.define_domain_xml(xml)
              else
                domain=connection.raw.create_domain_xml(xml)
              end
              self.raw=domain
            end
          rescue
            raise Fog::Errors::Error.new("Error saving the server: #{$!}")
          end
        end

        def create_or_clone_volume

          volume_options=Hash.new

          unless self.volume_name.nil?
            volume_options[:name]=self.volume_name
          else
            extension = self.volume_format_type.nil? ? "img" : self.volume_format_type
            volume_name = "#{self.name}.#{extension}"
            volume_options[:name]=volume_name
          end

          # Check if a disk template was specified
          unless self.volume_template_name.nil?

            template_volumes=connection.volumes.all(:name => self.volume_template_name)

            raise Fog::Errors::Error.new("Template #{self.volume_template_name} not found") unless template_volumes.length==1

            orig_volume=template_volumes.first
            self.volume_format_type=orig_volume.format_type unless self.volume_format_type
            volume=orig_volume.clone("#{volume_options[:name]}")

            # This gets passed to the domain to know the path of the disk
            self.volume_path=volume.path

          else
            # If no template volume was given, let's create our own volume

            volume_options[:format_type]=self.volume_format_type unless self.volume_format_type.nil?
            volume_options[:capacity]=self.volume_capacity unless self.volume_capacity.nil?
            volume_options[:allocation]=self.volume_allocation unless self.volume_allocation.nil?

            begin
              volume=connection.volumes.create(volume_options)
              self.volume_path=volume.path
              self.volume_format_type=volume.format_type unless self.volume_format_type
            rescue
              raise Fog::Errors::Error.new("Error creating the volume : #{$!}")
            end

          end
        end

        def validate_template_options
          unless self.network_interface_type.nil?
            raise Fog::Errors::Error.new("#{self.network_interface_type} is not a supported interface type") unless ["nat", "bridge"].include?(self.network_interface_type)
          end
        end

        def xml_from_template

          template_options={
            :cpus => self.cpus,
            :memory_size => self.memory_size,
            :domain_type => self.domain_type,
            :name => self.name,
            :iso_file => self.iso_file,
            :iso_dir => self.iso_dir,
            :os_type => self.os_type,
            :arch => self.arch,
            :volume_path => self.volume_path,
            :volume_format_type => self.volume_format_type,
            :network_interface_type => self.network_interface_type,
            :network_nat_network => self.network_nat_network,
            :network_bridge_name => self.network_bridge_name
          }
          vars = ErbBinding.new(template_options)
          template_path=File.join(File.dirname(__FILE__),"templates","server.xml.erb")
          template=File.open(template_path).readlines.join
          erb = ERB.new(template)
          vars_binding = vars.send(:get_binding)
          result=erb.result(vars_binding)
          return result
        end

        def username
          @username ||= 'root'
        end

        def start
          requires :raw

          unless @raw.active?
            begin
              @raw.create
              true
            rescue
              false
            end
          end
        end

        # In libvirt a destroy means a hard power-off of the domain
        # In fog a destroy means the remove of a machine
        def destroy(options={ :destroy_volumes => false})
          requires :raw
          if @raw.active?
            @raw.destroy
          end
          @raw.undefine
        end


        def reboot
          requires :raw
          @raw.reboot
        end

        # Alias for poweroff
        def halt
           poweroff
        end

        # In libvirt a destroy means a hard power-off of the domain
        # In fog a destroy means the remove of a machine
        def poweroff
          requires :raw
          @raw.destroy
        end

        def shutdown
          requires :raw
          @raw.shutdown
        end

        def resume
          requires :raw
          @raw.resume
        end

        def suspend
          requires :raw
          @raw.suspend
        end

        def to_fog_state(raw_state)
          state=case raw_state
                when 0 then "nostate"
                when 1 then "running"
                when 2 then "blocked"
                when 3 then "paused"
                when 4 then "shutting-down"
                when 5 then "shutoff"
                when 6 then "crashed"
                end
          return state
        end

        def ready?
          state == "running"
        end

        def stop
          requires :raw

          @raw.shutdown
        end

        #def xml_desc
          #requires :raw
          #raw.xml_desc
        #end

        # This retrieves the ip address of the mac address
        # It returns an array of public and private ip addresses
        # Currently only one ip address is returned, but in the future this could be multiple
        # if the server has multiple network interface
        #
        def addresses(options={})
          mac=self.mac

          # Aug 24 17:34:41 juno arpwatch: new station 10.247.4.137 52:54:00:88:5a:0a eth0.4
          # Aug 24 17:37:19 juno arpwatch: changed ethernet address 10.247.4.137 52:54:00:27:33:00 (52:54:00:88:5a:0a) eth0.4
          # Check if another ip_command string was provided
          ip_command_global=@connection.ip_command.nil? ? 'grep $mac /var/log/arpwatch.log|sed -e "s/new station//"|sed -e "s/changed ethernet address//g" |tail -1 |cut -d ":" -f 4-| cut -d " " -f 3' : @connection.ip_command
          ip_command_local=options[:ip_command].nil? ? ip_command_global : options[:ip_command]

          ip_command="mac=#{mac}; "+ip_command_local

          ip_address=nil

          if @connection.uri.ssh_enabled?

            # Retrieve the parts we need from the connection to setup our ssh options
            user=connection.uri.user #could be nil
            host=connection.uri.host
            keyfile=connection.uri.keyfile
            port=connection.uri.port

            # Setup the options
            ssh_options={}
            ssh_options[:keys]=[ keyfile ] unless keyfile.nil?
            ssh_options[:port]=port unless keyfile.nil?
            ssh_options[:paranoid]=true if connection.uri.no_verify?

            # TODO: we need to take the time into account, when IP's are re-allocated, we might be executing
            # On the wrong host

            begin
              result=Fog::SSH.new(host, user, ssh_options).run(ip_command)
            rescue Errno::ECONNREFUSED
              raise Fog::Errors::Error.new("Connection was refused to host #{host} to retrieve the ip_address for #{mac}")
            rescue Net::SSH::AuthenticationFailed
              raise Fog::Errors::Error.new("Error authenticating over ssh to host #{host} and user #{user}")
            end

            #TODO: We currently just retrieve the ip address through the ip_command
            #TODO: We need to check if that ip_address is still valid for that mac-address

            # Check for a clean exit code
            if result.first.status == 0
              ip_address=result.first.stdout.strip
            else
              # We got a failure executing the command
              raise Fog::Errors::Error.new("The command #{ip_command} failed to execute with a clean exit code")
            end

          else
            # It's not ssh enabled, so we assume it is
            if @connection.uri.transport=="tls"
              raise Fog::Errors::Error.new("TlS remote transport is not currently supported, only ssh")
            end

            # Execute the ip_command locally
            # Initialize empty ip_address string
            ip_address=""

            IO.popen("#{ip_command}") do |p|
              p.each_line do |l|
                ip_address+=l
              end
              status=Process.waitpid2(p.pid)[1].exitstatus
              if status!=0
                raise Fog::Errors::Error.new("The command #{ip_command} failed to execute with a clean exit code")
              end
            end

            #Strip any new lines from the string
            ip_address=ip_address.chomp
          end


          # The Ip-address command has been run either local or remote now

          if ip_address==""
            #The grep didn't find an ip address result"
            ip_address=nil
          else
            # To be sure that the command didn't return another random string
            # We check if the result is an actual ip-address
            # otherwise we return nil
            unless ip_address=~/^(\d{1,3}\.){3}\d{1,3}$/
              raise Fog::Errors::Error.new(
                "The result of #{ip_command} does not have valid ip-address format\n"+
                "Result was: #{ip_address}\n"
            )
            end
          end

          return { :public => [ip_address], :private => [ip_address]}
        end

        def private_ip_address
          ip_address(:private)
        end

        def public_ip_address
          ip_address(:public)
        end

        def ip_address(key)
          ips=addresses[key]
          unless ips.nil?
            return ips.first
          else
            return nil
          end
        end

        def private_key_path
          @private_key_path ||= Fog.credentials[:private_key_path]
          @private_key_path &&= File.expand_path(@private_key_path)
        end

        def private_key
          @private_key ||= private_key_path && File.read(private_key_path)
        end

        def public_key_path
          @public_key_path ||= Fog.credentials[:public_key_path]
          @public_key_path &&= File.expand_path(@public_key_path)
        end

        def public_key
          @public_key ||= public_key_path && File.read(public_key_path)
        end

        def ssh(commands)
          requires :public_ip_address, :username

          #requires :password, :private_key
          ssh_options={}
          ssh_options[:password] = password unless password.nil?
          ssh_options[:key_data] = [private_key] if private_key
          ssh_options[:proxy]= ssh_proxy unless ssh_proxy.nil?

          Fog::SSH.new(public_ip_address, @username, ssh_options).run(commands)

        end


        def ssh_proxy
          proxy=nil
          if @connection.uri.ssh_enabled?
            relay=connection.uri.host
            user_string=""
            user_string="-l #{connection.uri.user}" unless connection.uri.user.nil?
            proxy = Net::SSH::Proxy::Command.new("ssh #{user_string} "+relay+" nc %h %p")
            return proxy
          else
            return nil
            # This is a direct connection, so we don't need a proxy to be set
          end
        end

        # Transfers a file
        def scp(local_path, remote_path, upload_options = {})
          requires :public_ip_address, :username

          scp_options = {}
          scp_options[:password] = password unless self.password.nil?
          scp_options[:key_data] = [private_key] if self.private_key
          scp_options[:proxy]= ssh_proxy unless self.ssh_proxy.nil?

          Fog::SCP.new(public_ip_address, username, scp_options).upload(local_path, remote_path, upload_options)
        end


        # Sets up a new key
        def setup(credentials = {})
          requires :public_key, :public_ip_address, :username
          require 'multi_json'

          credentials[:proxy]= ssh_proxy unless ssh_proxy.nil?
          credentials[:password] = password unless self.password.nil?
          credentails[:key_data] = [private_key] if self.private_key

          commands = [
            %{mkdir .ssh},
            #              %{passwd -l #{username}}, #Not sure if we need this here
            #              %{echo "#{MultiJson.encode(attributes)}" >> ~/attributes.json}
          ]
          if public_key
            commands << %{echo "#{public_key}" >> ~/.ssh/authorized_keys}
          end

          # wait for domain to be ready
          Timeout::timeout(360) do
            begin
              Timeout::timeout(8) do
                Fog::SSH.new(public_ip_address, username, credentials.merge(:timeout => 4)).run('pwd')
              end
            rescue Errno::ECONNREFUSED
              sleep(2)
              retry
            rescue Net::SSH::AuthenticationFailed, Timeout::Error
              retry
            end
          end
          Fog::SSH.new(public_ip_address, username, credentials).run(commands)
        end

        # Retrieves the mac address from parsing the XML of the domain
        def mac
          mac = document("domain/devices/interface/mac", "address")
          return mac
        end

        def vnc_port

          port = document("domain/devices/graphics[@type='vnc']", "port")
          return port
        end


        private

        def raw
          @raw
        end

        def raw=(new_raw)
          @raw = new_raw

          raw_attributes = {
            :id => new_raw.uuid,
            :uuid => new_raw.uuid,
            :name => new_raw.name,
            :max_memory_size => new_raw.info.max_mem,
            :cputime => new_raw.info.cpu_time,
            :memory_size => new_raw.info.memory,
            :vcpus => new_raw.info.nr_virt_cpu,
            :autostart => new_raw.autostart?,
            :os_type => new_raw.os_type,
            :xml => new_raw.xml_desc,
            :state => self.to_fog_state(new_raw.info.state)
          }

          merge_attributes(raw_attributes)
        end


        # finds a value from xml
        def document path, attribute=nil
          xml = REXML::Document.new(self.xml)
          attribute.nil? ? xml.elements[path].text : xml.elements[path].attributes[attribute]
        end


      end

    end
  end

end
