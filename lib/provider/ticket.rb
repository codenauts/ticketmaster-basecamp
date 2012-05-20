module TicketMaster::Provider
  module Basecamp
    # Ticket class for ticketmaster-basecamp
    #
    #
    # * status => completed (either completed or incomplete)
    # * priority => position
    # * title => TodoList#name - TodoItem#content (up to 100 characters)
    # * resolution => completed (either completed or '')
    # * updated_at => completed_on
    # * description => content
    # * assignee => responsible_party_name (read-only)
    # * requestor => creator_name (read-only)
    # * project_id
    class Ticket < TicketMaster::Provider::Base::Ticket
      attr_accessor :list
      def self.find_by_id(project_id, id)
        self.search(project_id, {'id' => id.to_i}).first
      end
      
      def self.find_by_attributes(project_id, attributes = {})
        self.search(project_id, attributes)
      end
      
      def self.todo_lists(project_id)
        BasecampAPI::TodoList.find(:all, :params => {:project_id => project_id})
      end

      def self.search(project_id, options = {}, limit = 1000)
        tickets = todo_lists(project_id).collect do |list|
          list.todo_items.collect { |item|
            item.attributes['list'] = list
            item
            }
          end.flatten.collect { |ticket| self.new(ticket, ticket.attributes.delete('list')) }
        search_by_attribute(tickets, options, limit)
      end
      
      # It expects a single hash
      def self.create(*options)
        if options.first.is_a?(Hash)
          list_id = options[0].delete(:todo_list_id) || options[0].delete('todo_list_id')
          project_id = options[0].delete(:project_id) || options[0].delete('project_id')
          if list_id.nil? and project_id
            list_id = BasecampAPI::TodoList.create(:project_id => project_id, :name => 'New List').id
          end
          options[0][:todo_list_id] = list_id
        end
        something = BasecampAPI::TodoItem.new(options.first)
        something.save
        self.new something
      end
      
      def initialize(*object)
        if object.first
          object = object.first
          @system_data = {:client => object}
          unless object.is_a? Hash
            hash = {
              :id => object.id,
              :title => object.content
            }
          else
            hash = object
          end
          super hash
        end
      end
      
      def description
        nil
      end
      
      def comment!(*options)
        options[0].merge!(:todo_item_id => id) if options.first.is_a?(Hash)
        self.class.parent::Comment.create(*options)
      end
    end
  end
end
