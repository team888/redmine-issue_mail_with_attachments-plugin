
require File.expand_path('../../test_helper', __FILE__)

class MailPatchEditStatusTest < ActiveSupport::TestCase
  include Redmine::I18n
  include Rails::Dom::Testing::Assertions

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :journals, :journal_details,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values,
           :time_entries,
           :attachments

  def setup
    @default_title_wo_status = false
  end
  
  def generate_data_with_attachment_001(num=3)
    issue = Issue.find(3)
    user = User.first
    
    att_files = [
      ["testfile.txt", "text/plain"],
      ["2010/11/101123161450_testfile_1.png", "image/png"],
      ["japanese-utf-8.txt", "text/plain"]
      ]

    journal = issue.init_journal(user, issue)
    atts = []
    (0..num -1).each do |idx|
      att = Attachment.new(
                       :file => uploaded_test_file(att_files[idx][0], att_files[idx][1]),
                       :author_id => 3
                     )
      assert att.save
      atts << att
      journal.journalize_attachment(att, :added)
    end

    return issue, atts, journal
  end
  
  def test__att_enabled_true__attach_all_false
    ActionMailer::Base.deliveries.clear
    issue, atts = generate_data_with_attachment_001 1
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      
      :mail_subject => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject,
      :mail_subject_wo_status => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject_wo_status,
      :mail_subject_4_attachment => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject_4_attachment
    })
    
    issue.status_id = 4
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_dedicated_mails num_att_mails:1, atts:atts, issue:issue, title_wo_status:@default_title_wo_status
    end
  end

  def test__att_enabled_true__attach_all_true
    ActionMailer::Base.deliveries.clear
    issue, atts = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'true',
      
      :mail_subject => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject,
      :mail_subject_wo_status => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject_wo_status,
      :mail_subject_4_attachment => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject_4_attachment
    })
    
    issue.status_id = 4
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_attach_all atts:atts, issue:issue, title_wo_status:@default_title_wo_status
    end
  end

  def test__att_enabled_false__att_all_false
    ActionMailer::Base.deliveries.clear
    issue, atts = generate_data_with_attachment_001
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'false',
      :attach_all_to_notification => 'false',
      
      :mail_subject => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject,
      :mail_subject_wo_status => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject_wo_status,
      :mail_subject_4_attachment => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject_4_attachment
    })
    
    issue.status_id = 4
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do
      assert issue.save
      assert_sent_with_no_attachments issue:issue, title_wo_status:@default_title_wo_status
    end
  end

end
