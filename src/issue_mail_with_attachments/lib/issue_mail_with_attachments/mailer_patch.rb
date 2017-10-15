
module IssueMailWithAttachments
  module MailerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        alias_method_chain :issue_add, :attachments
        alias_method_chain :issue_edit, :attachments
      end
    end

    module InstanceMethods
      #=========================================================
      # monkey patch for issue_add method of Mailer class
      #=========================================================
      def issue_add_with_attachments(issue, to_users, cc_users)
        prev_logger_lvl = nil
        prev_logger_lvl = Rails.logger.level
        Rails.logger.level = Logger::DEBUG
        Rails.logger.debug "--- def issue_add_with_attachments ------"
        #------------------------------------------------------------
        # call original method
        #------------------------------------------------------------
        ml = issue_add_without_attachments(issue, to_users, cc_users)

        #------------------------------------------------------------
        # evaluate plugin settings
        #------------------------------------------------------------
        # plugin setting value: enable/disable file attachments
        att_enabled = Setting.plugin_issue_mail_with_attachments['enable_mail_attachments'].to_s.eql?('true') ? true : false
        # plugin setting value: attach all files on original notification mail
        attach_all = Setting.plugin_issue_mail_with_attachments['attach_all_to_notification'].to_s.eql?('true') ? true : false

        # project level plugin setting: enabled/disabled as project module setting
        mod_enabled = issue.project.module_enabled?("issue_mail_with_attachments_plugin")
        # plugin setting value: enable/disable project level control
        prj_ctl_enabled = Setting.plugin_issue_mail_with_attachments['enable_project_level_control'].to_s.eql?('true') ? true : false

        # plugin setting value: custom filed name for issue level control
        enabled_for_issue = true
        cf_name_for_issue = Setting.plugin_issue_mail_with_attachments['field_name_to_enable_att']
        if cf_name_for_issue
          cf = issue.custom_field_values.detect {|c| c.custom_field.name == cf_name_for_issue}
          if cf
            Rails.logger.debug "cf.value: #{cf.value}"
            enabled_for_issue = false unless cf.value.to_s.eql?('1')
          end
        end

        with_att = true
        with_att = false unless att_enabled
        with_att = false if mod_enabled == false and prj_ctl_enabled == true
        with_att = false unless enabled_for_issue
        Rails.logger.debug "******  with_att:#{with_att}, att_enabled: #{att_enabled}, attach_all: #{attach_all}, mod_enabled: #{mod_enabled}, prj_ctl_enabled: #{prj_ctl_enabled}, cf_name_for_issue: #{cf_name_for_issue}, enabled_for_issue: #{enabled_for_issue}"
        
        # little bit tricky way, really work ... ?
        initialize
        #------------------------------------------------------------
        # attach all files on original notification mail
        #------------------------------------------------------------
        if attach_all == true and with_att == true
          #unless Setting.plain_text_mail?
            issue.attachments.each do |attachment|
              Rails.logger.debug "***  att with notification: #{attachment.filename}"
              attachments[attachment.filename] = File.binread(attachment.diskfile)
            end
          #end
        end
        # plugin setting value: mail subject
        s = Setting.plugin_issue_mail_with_attachments['mail_subject']
        s = eval("\"#{s}\"")
#        s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
        #-----------
        # mail
        #-----------
        # note: overwrite original mail method ... work ?
        if Redmine::VERSION::MAJOR == 2
          ml = mail :to => to_users.map(&:mail),
           :cc => cc_users.map(&:mail),
           :subject => s
        else                      # for feature #4244, from redmine v3.0.0
          ml = mail :to => to_users,
           :cc => cc_users,
           :subject => s
        end
        
        #------------------------------------------------------------
        # send each files on dedicated mails
        #------------------------------------------------------------
        if attach_all == false and with_att == true
          # plugin setting value: mail subject for attachment
          ss = Setting.plugin_issue_mail_with_attachments['mail_subject_4_attachment']
          ss = eval("\"#{ss}\"")
#          ss = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] |att| "
          # send mail with attachments
          #unless Setting.plain_text_mail?
            issue.attachments.each do |attachment|
              Rails.logger.debug "***  att with notification: #{attachment.filename}"
              ml.deliver    # last deliver method will be called in caller - deliver_issue_edit method
              initialize
              attachments[attachment.filename] = File.binread(attachment.diskfile)
              sss = ss + attachment.filename
              #-----------
              # mail
              #-----------
              if Redmine::VERSION::MAJOR == 2
                ml = mail( :to => to_users.map(&:mail),
                  :cc => cc_users.map(&:mail),
                  :subject => sss
                ) do |format|
                  format.text { render plain: attachment.filename }
                  format.html { render html: "#{attachment.filename}".html_safe }
                end
              else                      # for feature #4244, from redmine v3.0.0
                ml = mail( :to => to_users,
                  :cc => cc_users,
                  :subject => sss
                ) do |format|
                  format.text { render plain: attachment.filename }
                  format.html { render html: "#{attachment.filename}".html_safe }
                end
              end
            end
          #end
        end
        Rails.logger.level = prev_logger_lvl if prev_logger_lvl
      end

      #=========================================================
      # monkey patch for issue_edit method of Mailer class
      #=========================================================
      def issue_edit_with_attachments(journal, to_users, cc_users)
        prev_logger_lvl = nil
        prev_logger_lvl = Rails.logger.level
        Rails.logger.level = Logger::DEBUG
        Rails.logger.debug "--- def issue_edit_with_attachments ------"
        #------------------------------------------------------------
        # call original method
        #------------------------------------------------------------
        ml = issue_edit_without_attachments(journal, to_users, cc_users)
        issue = journal.journalized

        #------------------------------------------------------------
        # evaluate plugin settings
        #------------------------------------------------------------
        # plugin setting value: enable/disable file attachments
        att_enabled = Setting.plugin_issue_mail_with_attachments['enable_mail_attachments'].to_s.eql?('true') ? true : false
        # plugin setting value: attach all files on original notification mail
        attach_all = Setting.plugin_issue_mail_with_attachments['attach_all_to_notification'].to_s.eql?('true') ? true : false

        # project level plugin setting: enabled/disabled as project module setting
        mod_enabled = issue.project.module_enabled?("issue_mail_with_attachments_plugin")
        # plugin setting value: enable/disable project level control
        prj_ctl_enabled = Setting.plugin_issue_mail_with_attachments['enable_project_level_control'].to_s.eql?('true') ? true : false

        # plugin setting value: custom filed name for issue level control
        enabled_for_issue = true
        cf_name_for_issue = Setting.plugin_issue_mail_with_attachments['field_name_to_enable_att']
        if cf_name_for_issue
          cf = issue.custom_field_values.detect {|c| c.custom_field.name == cf_name_for_issue}
          if cf
            Rails.logger.debug "cf.value: #{cf.value}"
            enabled_for_issue = false unless cf.value.to_s.eql?('1')
          end
        end

        with_att = true
        with_att = false unless att_enabled
        with_att = false if mod_enabled == false and prj_ctl_enabled == true
        with_att = false unless enabled_for_issue
        Rails.logger.debug "******  with_att:#{with_att}, att_enabled: #{att_enabled}, attach_all: #{attach_all}, mod_enabled: #{mod_enabled}, prj_ctl_enabled: #{prj_ctl_enabled}, cf_name_for_issue: #{cf_name_for_issue}, enabled_for_issue: #{enabled_for_issue}"

        # little bit tricky way, really work ... ?
        initialize
        #------------------------------------------------------------
        # attach all files on original notification mail
        #------------------------------------------------------------
        if attach_all == true and with_att == true
          #unless Setting.plain_text_mail?
            journal.details.each do |detail|
              if detail.property == 'attachment' && attachment = Attachment.find_by_id(detail.prop_key)
                Rails.logger.debug "***  att with notification: #{attachment.filename}"
                attachments[attachment.filename] = File.binread(attachment.diskfile)
              end
            end
          #end
        end
        if journal.new_value_for('status_id')
          # plugin setting value: mail subject
          s = Setting.plugin_issue_mail_with_attachments['mail_subject']
          s = eval("\"#{s}\"")
#          s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
        else
          # plugin setting value: mail subject without status
          s = Setting.plugin_issue_mail_with_attachments['mail_subject_wo_status']
          s = eval("\"#{s}\"")
#          s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] #{issue.subject}"
        end
        #-----------
        # mail
        #-----------
        # note: overwrite original mail method ... work ?
        if Redmine::VERSION::MAJOR == 2
          ml = mail :to => to_users.map(&:mail),
           :cc => cc_users.map(&:mail),
           :subject => s
        else                      # for feature #4244, from redmine v3.0.0
          ml = mail :to => to_users,
           :cc => cc_users,
           :subject => s
        end
        #------------------------------------------------------------
        # send each files on dedicated mails
        #------------------------------------------------------------
        if attach_all == false and with_att == true
          # plugin setting value: mail subject for attachment
          ss = Setting.plugin_issue_mail_with_attachments['mail_subject_4_attachment']
          ss = eval("\"#{ss}\"")
#          ss = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] |att| "

          # send mail with attachments
          #unless Setting.plain_text_mail?
            journal.details.each do |detail|
              if detail.property == 'attachment' && attachment = Attachment.find_by_id(detail.prop_key)
                Rails.logger.debug "***  att with dedicate mail: #{attachment.filename}"
                ml.deliver    # last deliver method will be called in caller - deliver_issue_edit method
                # little bit tricky way, really work ... ?
                initialize
                attachments[attachment.filename] = File.binread(attachment.diskfile)
                sss = ss + attachment.filename
                #-----------
                # mail
                #-----------
                if Redmine::VERSION::MAJOR == 2
                  ml = mail( :to => to_users.map(&:mail),
                    :cc => cc_users.map(&:mail),
                    :subject => sss
                  ) do |format|
                    format.text { render plain: attachment.filename }
                    format.html { render html: "#{attachment.filename}".html_safe }
                  end
                else                      # for feature #4244, from redmine v3.0.0
                  ml = mail( :to => to_users,
                    :cc => cc_users,
                    :subject => sss
                  ) do |format|
                    format.text { render plain: attachment.filename }
                    format.html { render html: "#{attachment.filename}".html_safe }
                  end
                end
              end
            end
          #end
        end
        Rails.logger.level = prev_logger_lvl if prev_logger_lvl
      end
    end
  end
end

