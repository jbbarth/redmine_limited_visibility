module Redmine
  module Export
    module PDF
      module IssuesPdfHelper

        # fetch row values
        def fetch_row_values(issue, query, level)
          query.inline_columns.collect do |column|
            if column.name == :has_been_assigned_to
              # patch
              s = get_assigned_users_and_functions(column, issue, false)
            else
              # core method
              s = if column.is_a?(QueryCustomFieldColumn)
                  cv = issue.visible_custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
                  show_value(cv, false)
                else
                  value = issue.send(column.name)
                  if column.name == :subject
                    value = "  " * level + value
                  end
                  if value.is_a?(Date)
                    format_date(value)
                  elsif value.is_a?(Time)
                    format_time(value)
                  else
                    value
                  end
                end
            end
            s.to_s
          end
        end

      end
    end
  end
end
