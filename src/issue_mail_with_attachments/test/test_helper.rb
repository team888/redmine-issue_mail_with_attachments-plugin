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
  
  def assert_sent_with_dedicated_mails(num_att_mails:3, atts:nil, issue:nil, attachment:nil, journal:nil, journal_detail:nil, title_wo_status:false, recipients:recipients)
    assert_equal (num_att_mails + 1) * recipients.size, ActionMailer::Base.deliveries.size

    recipients.size.times do |b|
      off = (b + 1) * (num_att_mails + 1)
      (1..(num_att_mails)).each do |r|
        m = ActionMailer::Base.deliveries[off - r]
        assert_equal [recipients[b]], m.bcc
        assert_equal 1, m.attachments.size
        if atts and issue
          assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject_4_attachment]}\"") + atts[num_att_mails - r].filename, m.subject
        end
        assert_mail_headers(m, issue)
      end
    
      m = ActionMailer::Base.deliveries[off - (num_att_mails +1)]
      assert_equal [recipients[b]], m.bcc
      assert_equal 0, m.attachments.size
      if issue
        if title_wo_status
          assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject_wo_status]}\""), m.subject 
        else
          assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject]}\""), m.subject 
        end
      end
    end
  end
  
  def assert_sent_with_attach_all(atts:nil, issue:nil, attachment:nil, journal:nil, journal_detail:nil, title_wo_status:false, recipients:recipients)
    assert_equal recipients.size, ActionMailer::Base.deliveries.size
    recipients.size.times do |b|
      m = ActionMailer::Base.deliveries[b]
      assert_equal [recipients[b]], m.bcc
      assert_equal atts.size, m.attachments.size
      if issue
        if title_wo_status
          assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject_wo_status]}\""), m.subject 
        else
          assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject]}\""), m.subject 
        end
      end
      assert_mail_headers(m, issue)
    end
  end

  def assert_sent_with_no_attachments(issue:nil, title_wo_status:false, recipients:recipients)
    assert_equal recipients.size, ActionMailer::Base.deliveries.size
    recipients.size.times do |b|
      m = ActionMailer::Base.deliveries[b]
      assert_equal [recipients[b]], m.bcc
      assert_equal 0, m.attachments.size
      if issue
        if title_wo_status
          assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject_wo_status]}\""), m.subject 
        else
          assert_equal eval("\"#{Setting.plugin_issue_mail_with_attachments[:mail_subject]}\""), m.subject 
        end
      end
      assert_mail_headers(m, issue)
    end
  end
  
  def assert_mail_headers(mail, issue)
    if issue
      assert_equal issue.project.identifier.to_s, mail.header['X-Redmine-Project'].to_s
      assert_equal issue.id.to_s, mail.header['X-Redmine-Issue-Id'].to_s
      assert_equal issue.author.login.to_s, mail.header['X-Redmine-Issue-Author'].to_s
      assert_equal issue.assigned_to.login.to_s, mail.header['X-Redmine-Issue-Assignee'].to_s if issue.assigned_to
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