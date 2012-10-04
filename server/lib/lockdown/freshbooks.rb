# freshbooks.rb

require "ruby-freshbooks"

module Lockdown
  class Freshbooks
    attr_reader :client

    PER_PAGE = 25

    def initialize(account, token)
      @client = FreshBooks::Client.new(account, token)
    end

    def connection
      @client
    end

    def update_client(pkg)
      connection.client.update pkg
    end

    # Return raw client hashes from active folder (deals with pagination too)
    def active_clients
      return @active_clients if @active_clients

      @active_clients = []

      # handle FreshBooks pagination
      more  = true
      page  = 1
      pages = 1

      while more
        response = connection.client.list page: page, per_page: PER_PAGE

        if clients = response["clients"]
          page  = Integer(clients["page"])
          pages = Integer(clients["pages"])

          clients["client"].select{ |c| c["folder"] == "active" }.each do |client|
            @active_clients << client
          end

          page += 1
          more = page <= pages
        end
      end

      @active_clients
    end

    # Create a lookup hash to help find clients when needed
    def active_client_cache
      return @active_client_cache if @active_client_cache

      @active_client_cache = {}.tap do |cache|
        active_clients.each do |client|
          cache[client["client_id"]] = client
        end
      end
    end

    # Return array of hashes, one for each client with contacts contained therein
    def active_client_contacts
      return @active_client_contacts if @active_client_contacts

      @active_client_contacts = []

      active_clients.each do |client|
        @active_client_contacts << {}.tap do |c|
          c["client_id"]    = client["client_id"]
          c["organization"] = client["organization"]
          c["contacts"] = [].tap do |contacts|
            # extract main contact from the
            contacts << {}.tap do |mc|
              mc["contact_id"]   = "main"
              mc["first_name"]   = client["first_name"]
              mc["last_name"]    = client["last_name"]
              mc["email"]        = client["email"]
              mc["phone1"]       = client["home_phone"]
              mc["phone2"]       = client["mobile"]
            end

            # add all contacts for client
            if client["contacts"]
              Array[client["contacts"]["contact"]].flatten.each do |contact|
                contacts << {}.tap do |c|
                  c["contact_id"]   = contact["contact_id"]
                  c["first_name"]   = contact["first_name"]
                  c["last_name"]    = contact["last_name"]
                  c["email"]        = contact["email"]
                  c["phone1"]       = contact["phone1"]
                  c["phone2"]       = contact["phone2"]
                end
              end
            end

          end
        end
      end

      @active_client_contacts
    end

    # Return flattened list of contacts
    def active_contacts
      return @active_contacts if @active_contacts

      @active_contacts = []

      active_client_contacts.each do |client|
        client_hash = {
          "client_id"    => client["client_id"],
          "organization" => client["organization"]
        }

        client["contacts"].each do |contact|
          @active_contacts << client_hash.tap do |c|
            c.merge! contact
          end
        end
      end

      @active_contacts
    end

    def active_email_list
      active_contacts.map{ |c| c["email"] }
    end

    def formatted_active_email_list
      active_email_list.join(", ")
    end

    # Keys are stored in 'phone2' of the contact
    def active_keys
      return @active_keys if @active_keys

      @active_keys = {}

      fb.active_client_contacts.each do |client|
        client["contacts"].each do |contact|
          key  = "#{contact["phone2"]}"
          name = "#{contact["first_name"]} #{contact["last_name"]}"

          @active_keys[key] = name if "#{key}".strip.empty?
        end
      end

      @active_keys
    end

    def active_keys_json
      active_keys.to_json
    end

  end
end
