require_dependency 'issues_helper'
include ERB::Util

module PluginLimitedVisibility
  module IssuesHelperPatch

    # Returns the textual representation of a single journal detail
    # Core properties are 'attr', 'attachment' or 'cf' : this patch specify how to display 'attr' journal details when the updated field is 'authorized_viewers'
    def show_detail(detail, no_html = false, options = {})

      if detail.property == 'attr' && detail.prop_key == 'authorized_viewers'

        label = l(:field_authorized_viewers)
        value = Function.functions_from_authorized_viewers(detail.value).join(", ")
        old_value = Function.functions_from_authorized_viewers(detail.old_value).join(", ")

        unless no_html
          label = content_tag('strong', label)
          old_value = content_tag("i", h(old_value)) if detail.old_value
          old_value = content_tag("del", old_value) if detail.old_value and detail.value.blank?
          value = content_tag("i", html_escape(value)) if value
        end

        if detail.value.present?
          # authorized_viewers == "||" is considered as blank (= no functions authorized)
          if detail.old_value.present? && detail.old_value != "||"
            l(:text_journal_changed, label: label, old: old_value, new: value).html_safe
          else
            l(:text_journal_set_to, label: label, value: value).html_safe
          end
        else
          l(:text_journal_deleted, label: label, old: old_value).html_safe
        end

      else
        if detail.property == 'attr' && detail.prop_key == 'assigned_to_function_id'

          label = l(:field_assigned_to_function)
          current_function = Function.where('id = ?', detail.value)
          if current_function.present?
            value = current_function.first.name
          else
            value = detail.value
          end
          old_function = Function.where('id = ?', detail.old_value)
          if old_function.present?
            old_value = old_function.first.name
          else
            old_value = detail.old_value
          end

          unless no_html
            label = content_tag('strong', label)
            old_value = content_tag("i", h(old_value)) if detail.old_value
            old_value = content_tag("del", old_value) if detail.old_value and detail.value.blank?
            value = content_tag("i", html_escape(value)) if value
          end

          if detail.value.present?
            if detail.old_value.present?
              l(:text_journal_changed, label: label, old: old_value, new: value).html_safe
            else
              l(:text_journal_set_to, label: label, value: value).html_safe
            end
          else
            l(:text_journal_deleted, label: label, old: old_value).html_safe
          end

        else
          # Process standard fields
          super
        end
      end
    end
    
    def hidden_functions_for_tracker(issue)
        hidden_functions = ProjectFunctionTracker.joins(:project_function).includes(:project_function).where("project_id = ? AND tracker_id = ? AND visible != ?", issue.project_id, issue.tracker_id, true).map{ |c| c.function }
    end
  end
end

IssuesHelper.prepend PluginLimitedVisibility::IssuesHelperPatch
ActionView::Base.prepend IssuesHelper
