require_dependency 'query'

class Query

  alias_method :core_validate_query_filters, :validate_query_filters

  def validate_query_filters
    if filters.keys.include?("authorized_viewers")
      filters.each_key do |field|
        if values_for(field)
          case type_for(field)
            when :integer
              add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/^[+-]?\d+$/) }
            when :float
              add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/^[+-]?\d+(\.\d*)?$/) }
            when :date, :date_past
              case operator_for(field)
                when "=", ">=", "<=", "><"
                  add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && (!v.match(/^\d{4}-\d{2}-\d{2}$/) || (Date.parse(v) rescue nil).nil?) }
                when ">t-", "<t-", "t-", ">t+", "<t+", "t+", "><t+", "><t-"
                  add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/^\d+$/) }
              end
          end
        end

        add_filter_error(field, :blank) unless
            # filter requires one or more values
            (values_for(field) and !values_for(field).first.blank?) or
                # filter doesn't require any value
                ["o", "c", "!*", "*", "t", "ld", "w", "lw", "l2w", "m", "lm", "y", "mine"].include? operator_for(field)
      end if filters
    else
      core_validate_query_filters
    end
  end

end
