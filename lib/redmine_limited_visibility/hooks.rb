require File.dirname(__FILE__) + '/../../app/helpers/limited_visibility_helper'
include LimitedVisibilityHelper

module RedmineLimitedVisibility
  class Hooks < Redmine::Hook::ViewListener

    # Add our css/js on each page
    def view_layouts_base_html_head(context)
      stylesheet_link_tag("limited_visibility", plugin: "redmine_limited_visibility") +
          stylesheet_link_tag("font-awesome.min.css", :plugin => "redmine_limited_visibility") +
        javascript_include_tag('limited_visibility.js', plugin: 'redmine_limited_visibility')
    end


  end
end
