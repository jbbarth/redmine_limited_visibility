module RedmineLimitedVisibility
  class Hooks < Redmine::Hook::ViewListener

    # Add our css/js on each page
    def view_layouts_base_html_head(context)
      javascript_include_tag('limited_visibility.js', :plugin => 'redmine_limited_visibility')
    end

  end
end
