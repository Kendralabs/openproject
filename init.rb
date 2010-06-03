require 'redmine'

fail "upgrade ruby version, ruby < 1.8.7 suffers from Hash#hash bug" if {:a => 10}.hash != {:a => 10}.hash

Redmine::Plugin.register :redmine_reporting do
  name 'Reporting Plugin'
  author 'Konstantin Haase, Philipp Tessenow @ finnlabs'
  author_url 'http://finn.de/team'
  description 'The reporting plugin provides extended reporting functionality for Redmine including Cost Reports.'
  version '0.1'

  requires_redmine :version_or_higher => '0.9'
  requires_redmine_plugin :redmine_costs, :version_or_higher => '0.3'

  #register reporting_module including permissions
  project_module :reporting_module do
    #require_or_load 'costs_access_control_permission_patch'

    permission :view_cost_entries, {:costlog => [:details], :cost_reports => [:index]}
    permission :view_own_cost_entries, {:costlog => [:details], :cost_reports => [:index]},
      :granular_for => :view_cost_entries
  end

  # register additional permissions for the time log
  project_module :time_tracking do
    permission :view_own_time_entries, {:cost_reports => [:index]}, :granular_for => :view_time_entries
  end

  #menu extensions
  menu :top_menu, :cost_reports_global, {:controller => 'cost_reports', :action => 'index'},
    :caption => :cost_reports_title,
    :if => Proc.new {
      ( User.current.allowed_to?(:view_cost_objects, nil, :global => true) ||
        User.current.allowed_to?(:edit_cost_objects, nil, :global => true)
      )
    }

  menu :project_menu, :cost_reports_local, {:controller => 'cost_reports', :action => 'index'},
    :param => :project_id, :after => :cost_objects, :caption => :cost_reports_title
end
