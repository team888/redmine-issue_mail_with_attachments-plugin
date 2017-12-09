
require File.expand_path('../../test_helper', __FILE__)

class MailPatchAddOrigTest < ActiveSupport::TestCase
  include Redmine::I18n
  include Rails::Dom::Testing::Assertions

  fixtures :projects, :users, :email_addresses, :user_preferences, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :journals, :journal_details,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values,
           :time_entries

  def setup
  end

  # copy from issue_test.rb
  def test_create_should_send_email_notification
    ActionMailer::Base.deliveries.clear
    issue = Issue.new(:project_id => 1, :tracker_id => 1,
                      :author_id => 3, :status_id => 1,
                      :priority => IssuePriority.all.first,
                      :subject => 'test_create', :estimated_hours => '1:30')
    with_settings :notified_events => %w(issue_added) do
      assert issue.save
      assert_equal 1, ActionMailer::Base.deliveries.size
    end
  end

  def test_create_should_send_one_email_notification_with_both_settings
    ActionMailer::Base.deliveries.clear
    issue = Issue.new(:project_id => 1, :tracker_id => 1,
                      :author_id => 3, :status_id => 1,
                      :priority => IssuePriority.all.first,
                      :subject => 'test_create', :estimated_hours => '1:30')
    with_settings :notified_events => %w(issue_added issue_updated) do
      assert issue.save
      assert_equal 1, ActionMailer::Base.deliveries.size
    end
  end

  def test_create_should_not_send_email_notification_with_no_setting
    ActionMailer::Base.deliveries.clear
    issue = Issue.new(:project_id => 1, :tracker_id => 1,
                      :author_id => 3, :status_id => 1,
                      :priority => IssuePriority.all.first,
                      :subject => 'test_create', :estimated_hours => '1:30')
    with_settings :notified_events => [] do
      assert issue.save
      assert_equal 0, ActionMailer::Base.deliveries.size
    end
  end

end
