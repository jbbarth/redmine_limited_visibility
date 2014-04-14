require_dependency 'query'

class Query

  alias_method :core_validate_query_filters, :validate_query_filters

  # use standard method to validate filters form,
  # but ignore "can't be blank" error on authorized_viewers filter because it doesn't require any value
  def validate_query_filters
    core_validate_query_filters
    m = label_for('authorized_viewers') + " " + l(:blank, :scope => 'activerecord.errors.messages')
    errors.messages[:base] = errors.messages[:base]-[m] if errors.messages[:base].present? && errors.messages[:base].include?(m)
  end

end
