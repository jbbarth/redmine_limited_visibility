require_dependency 'issues_helper'

module IssuesHelper
  alias_method :plugin_visibility_core_show_detail, :show_detail

  # Returns the textual representation of a single journal detail
  # Core properties are 'attr', 'attachment' or 'cf' : this patch specify how to display 'attr' journal details when the updated field is 'authorized_viewers'
  def show_detail(detail, no_html = false, options = {})

    if detail.property == 'attr' && detail.prop_key == 'authorized_viewers'

      label = l(:field_authorized_viewers)
      value = involved_roles(detail.value).join(", ") if detail.value.present?
      old_value = involved_roles(detail.old_value).join(", ") if detail.old_value.present?

      unless no_html
        label = content_tag('strong', label)
        old_value = content_tag("i", h(old_value)) if detail.old_value
        old_value = content_tag("del", old_value) if detail.old_value and detail.value.blank?
        value = content_tag("i", html_escape(value)) if value
      end

      if detail.value.present?
        if detail.old_value.present?
          l(:text_journal_changed, :label => label, :old => old_value, :new => value).html_safe
        else
          l(:text_journal_set_to, :label => label, :value => value).html_safe
        end
      else
        l(:text_journal_deleted, :label => label, :old => old_value).html_safe
      end

    else
      # Process standard fields
      plugin_visibility_core_show_detail(detail, no_html, options)
    end

  end

  def involved_roles(authorized_viewers)
    Role.find(authorized_viewers.split('|').delete_if(&:blank?)) if authorized_viewers
  end
end
