module TicketMaster::Provider
  module Basecamp
    # Project class for ticketmaster-basecamp
    class Project < TicketMaster::Provider::Base::Project
      API = BasecampAPI::Project
      def initialize(*object) 
        if object.first
          object = object.first
          unless object.is_a? Hash
            hash = {:id => object.id,
                    :name => object.name,
                    :description => object.announcement,
                    :created_at => object.created_on,
                    :updated_at => object.last_changed_on}

          else
            hash = object
          end
          super hash
        end
      end
      
      def ticket!(*options)
        options[0].merge!(:project_id => id) if options.first.is_a?(Hash)
        self.class.parent::Ticket.create(*options)
      end

      def self.find_by_id(id)
        self.new API.find(id)
      end

      def self.find_by_attributes(attributes = {})
        self.search(attributes)
      end

      def self.search(options = {}, limit = 1000)
        projects = API.find(:all).collect { |project| self.new project }
        search_by_attribute(projects, options, limit)
      end
      
      # copy from this.copy(that) copies that into this
      def copy(project)
        project.tickets.each do |ticket|
          copy_ticket = self.ticket!(:title => ticket.title, :description => ticket.description)
          ticket.comments.each do |comment|
            copy_ticket.comment!(:body => comment.body)
            sleep 1
          end
        end
      end
    end
  end
end


