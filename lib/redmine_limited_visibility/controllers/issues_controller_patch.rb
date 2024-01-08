require_dependency 'issues_controller'

module RedmineLimitedVisibility
  module Controllers
    module IssuesControllerPatch
      extend ActiveSupport::Concern

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

      def forbid_assignation_to_function_if_module_is_not_enabled
        project = @project if @project.present?
        project = @issue.project if project.blank? && @issue.present?
        if project.present? && !project.module_enabled?("limited_visibility")
          @issue.assigned_to_function_id = ''
          params[:issue][:assigned_to_function_id] = '' if params[:issue]
        end
      end

      def set_previous_tracker_id
        @previous_tracker_id = params[:previous_tracker_id]
      end
    end
  end
end

class IssuesController < ApplicationController
  include RedmineLimitedVisibility::Controllers::IssuesControllerPatch

  prepend_before_action :set_assigned_to_function_id, :only => [:create, :update, :new, :edit]
  append_before_action :forbid_assignation_to_function_if_module_is_not_enabled, :only => [:create, :update, :new, :edit]

  before_action :set_previous_tracker_id, :only => [:new]
end
