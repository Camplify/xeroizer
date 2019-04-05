module Xeroizer
  module Record

    class ContactGroupModel < BaseModel
      set_permissions :read, :update

      def update_method
        :http_put
      end

      def http_put(xml, contact_group_id, extra_params = {})
        update_url = "#{url}/#{contact_group_id}/Contacts"
        application.http_put(application.client, update_url, xml, extra_params)
      end
    end

    class ContactGroup < Base

      CONTACT_GROUP_STATUS = {
          'ACTIVE' =>     'Active',
          'DELETED' =>    'Deleted',
          'ARCHIVED' => 'Archived'
      } unless defined?(CONTACT_GROUP_STATUS)

      set_primary_key :contact_group_id
      list_contains_summary_only true

      guid :contact_group_id
      string :name
      string :status

      has_many :contacts, :list_complete => true

      validates_inclusion_of :status, :in => CONTACT_GROUP_STATUS.keys, :allow_blanks => true

      def update
        if self.class.possible_primary_keys && self.class.possible_primary_keys.all? { | possible_key | self[possible_key].nil? }
          raise RecordKeyMustBeDefined.new(self.class.possible_primary_keys)
        end

        request = to_xml

        log "[UPDATE SENT] (#{__FILE__}:#{__LINE__}) \r\n#{request}"

        response = parent.send(parent.update_method, request, self.contact_group_id)

        log "[UPDATE RECEIVED] (#{__FILE__}:#{__LINE__}) \r\n#{response}"

        parse_save_response(response)
      end

      # Turn a record into its XML representation.
      def to_xml(b = Builder::XmlMarkup.new(:indent => 2))
        optional_root_tag(parent.class.optional_xml_root_name, b) do |c|
          c.tag!('Contacts') {
            attributes.except(:contact_group_id, :name, :status)[:contacts].each do |contact|
              c.tag!('Contact') {
                c.tag!('ContactID', contact[:contact_id])
              }
            end
          }
        end
      end

    end

  end
end
