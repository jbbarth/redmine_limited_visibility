require_dependency 'issues_controller'

class IssuesController < ApplicationController

  prepend_before_action :set_assigned_to_function_id, :only => [:create, :update, :new, :edit]

  before_action :set_previous_tracker_id, :only => [:new]

  private
    def set_assigned_to_function_id
      if params[:issue].present?
        if params[:issue][:assigned_to_id]
          if params[:issue][:assigned_to_id].to_s.include?("function")
            params[:issue][:assigned_to_id].slice! "function-"
            params[:issue][:assigned_to_function_id] = params[:issue][:assigned_to_id]
            params[:issue][:assigned_to_id] = ""
          else
            params[:issue][:assigned_to_function_id] = nil
          end
        end
      end
    end

    def set_previous_tracker_id
      @previous_tracker_id = params[:previous_tracker_id]
    end
end
