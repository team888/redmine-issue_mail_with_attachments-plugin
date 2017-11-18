# Coveralls configuration
if ENV['COVERALL4MYPLUGIN'] == 'true'
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  #SimpleCov.merge_timeout 3600
  SimpleCov.start do
     add_filter do |source_file|
       !source_file.filename.include? "/plugins/"
     end
     add_filter '/lib/plugins/'
     add_filter '/db/'
  end
  Coveralls.wear!('rails')
end

# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

  def assert_mail_subjects(subjects)
    subjects.zip(ActionMailer::Base.deliveries.slice(0, subjects.size)).each do |s, m|
      assert_equal s, m.subject
    end
  end
  
  def assert_sent_with_dedicated_mails(num_att_mails:3, atts:nil, issue:nil, attachment:nil, journal:nil, journal_detail:nil, title_wo_status:false)
    assert_equal num_att_mails +1, ActionMailer::Base.deliveries.size
    (1..(num_att_mails)).each do |r|
      m = ActionMailer::Base.deliveries[-r]
      assert_equal 1, m.attachments.size
      if atts and issue
#        p atts[num_att_mails - r].filename
        assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject_4_attachment]}\"") + atts[num_att_mails - r].filename, m.subject
      end
    end
    
    m = ActionMailer::Base.deliveries[-(num_att_mails +1)]
    assert_equal 0, m.attachments.size
    if issue
      if title_wo_status
        assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject_wo_status]}\""), m.subject 
      else
        assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject]}\""), m.subject 
      end
    end
  end
  
  def assert_sent_with_attach_all(atts:nil, issue:nil, attachment:nil, journal:nil, journal_detail:nil, title_wo_status:false)
      assert_equal 1, ActionMailer::Base.deliveries.size
      m = ActionMailer::Base.deliveries.last
      assert_equal 3, m.attachments.size
      if issue
        if title_wo_status
          assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject_wo_status]}\""), m.subject 
        else
          assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject]}\""), m.subject 
        end
      end
  end

  def assert_sent_with_no_attachments(issue:nil, title_wo_status:false)
      assert_equal 1, ActionMailer::Base.deliveries.size
      m = ActionMailer::Base.deliveries.last
      assert_equal 0, m.attachments.size
      if issue
        if title_wo_status
          assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject_wo_status]}\""), m.subject 
        else
          assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject]}\""), m.subject 
        end
      end
  end
  
  def plugin_settings_init(raw_settings)
    if Redmine::VERSION::MAJOR == 2
      return HashWithIndifferentAccess.new(raw_settings)
    else
      return ActionController::Parameters.new(raw_settings)
    end
  end

class IssueMailWithAttPluginInfo
  DEFAULT_edit_mail_subject = '[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}'
  DEFAULT_edit_mail_subject_wo_status = '[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] #{issue.subject}'
  DEFAULT_edit_mail_subject_4_attachment = '[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] |att| '

end