module ActiveAdmin::Sortable
  module ControllerActions

    attr_accessor :sortable_options

    def sortable(options = {})
      options.reverse_merge! :sorting_attribute => :position,
                             :parent_method => :parent,
                             :children_method => :children,
                             :roots_method => :roots,
                             :tree => false

      # BAD BAD BAD FIXME: don't pollute original class
      @sortable_options = options

      collection_action :sort, :method => :post do
        resource_name = active_admin_config.resource_name.underscore.parameterize('_')

        records = params[resource_name].inject({}) do |res, (resource, parent_resource)|
          res[resource_class.find(resource)] = resource_class.find(parent_resource) rescue nil
          res
        end
        errors = []
        records.each_with_index do |(record, parent_record), position|
          record.send "#{options[:sorting_attribute]}=", position
          if options[:tree]
            record.send "#{options[:parent_method]}=", parent_record
          end
          errors << {record.id => record.errors} if !record.save
        end
        if errors.empty?
          head 200
        else
          render json: errors, status: 422
        end
      end

    end

  end

  ::ActiveAdmin::ResourceDSL.send(:include, ControllerActions)
end