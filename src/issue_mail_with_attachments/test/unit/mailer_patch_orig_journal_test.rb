
require File.expand_path('../../test_helper', __FILE__)

class MailPatchEditOrigTest < ActiveSupport::TestCase
  include Redmine::I18n
  include Rails::Dom::Testing::Assertions

  fixtures :projects, :issues, :issue_statuses, :journals, :journal_details,
           :issue_relations, :workflows,
           :users, :members, :member_roles, :roles, :enabled_modules,
           :groups_users, :email_addresses,
           :enumerations,
           :projects_trackers, :trackers, :custom_fields

  def setup
  end

  # copy from journal_test.rb
  def test_create_should_send_email_notification
    ActionMailer::Base.deliveries.clear
    issue = Issue.first
    user = User.first
    journal = issue.init_journal(user, issue)

    assert journal.save
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

end
