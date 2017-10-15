#*******************************************************************************
# issue_mail_with_attachments Redmine plugin.
#
# Authors:
# - https://github.com/team888
#
# Terms of use:
# - GNU GENERAL PUBLIC LICENSE Version 2
#*******************************************************************************
Rails.logger.info 'Starting issue_mail_with_attachments Redmine plugin'

default_settings = {
    :enable_mail_attachments => true,
    :attach_all_to_notification => false,
    :mail_subject => '[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}',
    :mail_subject_wo_status => '[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] #{issue.subject}',
    :mail_subject_4_attachment => '[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] |att| '
}

if Redmine::VERSION::MAJOR == 2
  default_settings = HashWithIndifferentAccess.new(default_settings)
else
  default_settings = ActionController::Parameters.new(default_settings)
end

Redmine::Plugin.register :issue_mail_with_attachments do
  name 'Issue Mail With Attachments plugin'
  author 'team888'
  description 'With this plugin, you can send out newly attached files on issues via usual issue notification mails or dedicated mails as attachments.'
  version '0.9.0'
  url 'http://www.redmine.org/plugins/issue_mail_with_attachments'
  author_url 'https://github.com/team888'

  settings :default => default_settings, :partial => 'settings/issue_mail_with_attachments_settings'
  
  # show enable/disable on project setting
  project_module :issue_mail_with_attachments_plugin do
    # hidden dummy permission
    permission :dummy_permission, { }, :public => true, :read => true
  end

end


require "issue_mail_with_attachments/mailer_patch.rb"

Rails.configuration.to_prepare do
  require_dependency 'mailer'
  # load patch module
  unless Mailer.included_modules.include? IssueMailWithAttachments::MailerPatch
    Mailer.send(:include, IssueMailWithAttachments::MailerPatch)
  end
end
