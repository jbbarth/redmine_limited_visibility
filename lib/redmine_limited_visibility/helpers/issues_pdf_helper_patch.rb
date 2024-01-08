include CustomFieldsHelper

module RedmineLimitedVisibility
  module Helpers
    module IssuesPdfHelperPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method :fetch_row_values_without_limited_visibility_plugin, :fetch_row_values
        end
      end

      module InstanceMethods
        # fetch row values
        def fetch_row_values(object, query, level)
          if object.is_a? Issue
            query.inline_columns.collect do |column|
              if column.name == :has_been_assigned_to
                # patch
                s = get_assigned_users_and_functions(column, object, false)
              else
                # core method
                s = if column.is_a?(QueryCustomFieldColumn)
                      cv = object.visible_custom_field_values.detect { |v| v.custom_field_id == column.custom_field.id }
                      show_value(cv, false)
                    else
                      value = column.value_object(object)
                      case column.name
                      when :subject
                        value = "  " * level + value
                      when :attachments
                        value = value.to_a.map { |a| a.filename }.join("\n")
                      end
                      if value.is_a?(Date)
                        format_date(value)
                      elsif value.is_a?(Time)
                        format_time(value)
                      elsif value.is_a?(Float)
                        sprintf "%.2f", value
                      else
                        value
                      end
                    end
              end
              s.to_s
            end
          else
            fetch_row_values_without_limited_visibility_plugin(object, query, level)
          end
        end
      end

    end
  end
end

Redmine::Export::PDF::IssuesPdfHelper.include RedmineLimitedVisibility::Helpers::IssuesPdfHelperPatch
