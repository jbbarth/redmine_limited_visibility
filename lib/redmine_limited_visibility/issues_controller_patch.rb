require_dependency 'issues_controller'

class IssuesController < ApplicationController

  prepend_before_filter :set_assigned_to_function_id, :only => [:create, :update, :update_form]

  private
    def set_assigned_to_function_id
      if params[:issue].present? && params[:issue][:assigned_to_id].present?
        if params[:issue][:assigned_to_id].to_s.include?("function")
          params[:issue][:assigned_to_id].slice! "function-"
          params[:issue][:assigned_to_function_id] = params[:issue][:assigned_to_id]
          params[:issue][:assigned_to_id] = nil
        else
          params[:issue][:assigned_to_function_id] = nil
        end
      end
    end
end
