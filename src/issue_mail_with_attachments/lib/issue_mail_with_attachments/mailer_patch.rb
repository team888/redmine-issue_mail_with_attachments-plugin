
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
      # helper method to set logger level
      #=========================================================
      def set_logger_level()
        prev = nil
        prev = Rails.logger.level
        Rails.logger.level = Logger::DEBUG
        return prev
      end

      #=========================================================
      # helper method to retrieve plugin setting
      #=========================================================
      def retrieve_plugin_seting(name)
        return Setting.plugin_issue_mail_with_attachments[name]
      end
      
      #=========================================================
      # helper method to retrieve plugin setting
      #=========================================================
      def retrieve_and_eval_plugin_seting(issue, name, attachment:nil, journal:nil, journal_detail:nil)
        v = retrieve_plugin_seting(name)
        return eval("\"#{v}\"")
      end

      #=========================================================
      # helper class to store arguments
      #=========================================================
      class PluginSettings
        attr_accessor :att_enabled, :attach_all, :prj_ctl_enabled, :mod_enabled, :cf_name_for_issue, :enabled_for_issue
      end
      
      #=========================================================
      # helper method to retrieve plugin settings
      #=========================================================
      def retrieve_plugin_settings(issue)
        #------------------------------------------------------------
        # evaluate plugin settings
        #------------------------------------------------------------
        # plugin setting value: enable/disable file attachments
        att_enabled = retrieve_plugin_seting('enable_mail_attachments').to_s.eql?('true') ? true : false
        # plugin setting value: attach all files on original notification mail
        attach_all = retrieve_plugin_seting('attach_all_to_notification').to_s.eql?('true') ? true : false

        # project level plugin setting: enabled/disabled as project module setting
        mod_enabled = issue.project.module_enabled?("issue_mail_with_attachments_plugin")
        # plugin setting value: enable/disable project level control
        prj_ctl_enabled = retrieve_plugin_seting('enable_project_level_control').to_s.eql?('true') ? true : false

        # plugin setting value: custom filed name for issue level control
        enabled_for_issue = nil
        cf_name_for_issue = retrieve_plugin_seting('field_name_to_enable_att')
        if cf_name_for_issue
          cf = issue.custom_field_values.detect {|c| c.custom_field.name == cf_name_for_issue}
          if cf
            Rails.logger.debug "cf.value: #{cf.value}"
            if cf.value.to_s.eql?('1')
              enabled_for_issue = true
            else
              enabled_for_issue = false
            end
          end
        end
        ps = PluginSettings.new
        ps.att_enabled = att_enabled
        ps.attach_all = attach_all
        ps.prj_ctl_enabled = prj_ctl_enabled
        ps.mod_enabled = mod_enabled
        ps.cf_name_for_issue = cf_name_for_issue
        ps.enabled_for_issue = enabled_for_issue
        ps
      end

      #=========================================================
      # helper method to evaluate mail with attachment or not
      #=========================================================
      def evaluate_attach_or_not(ps)
        with_att = true
        with_att = false unless ps.att_enabled
        with_att = false if ps.mod_enabled != true and ps.prj_ctl_enabled == true
        with_att = false if ps.cf_name_for_issue and ps.enabled_for_issue == false
        Rails.logger.debug "****  with_att:#{with_att}, att_enabled: #{ps.att_enabled}, attach_all: #{ps.attach_all}, mod_enabled: #{ps.mod_enabled}, prj_ctl_enabled: #{ps.prj_ctl_enabled}, cf_name_for_issue: #{ps.cf_name_for_issue}, enabled_for_issue: #{ps.enabled_for_issue}"
        return with_att
      end
      module_function :evaluate_attach_or_not   # for unit testing
      
      #=========================================================
      # send with dedicated mail
      #=========================================================
      def send_first_mail(to_users, cc_users, title, issue)
        redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        ml = mail :to => to_users,
         :cc => cc_users,
         :subject => title
        return ml
      end
      
      #=========================================================
      # send with dedicated mail
      #=========================================================
      def send_with_dedicated_mail(to_users, cc_users, title, attachment, issue)
        initialize
        attachments[attachment.filename] = File.binread(attachment.diskfile)
        new_title = title + attachment.filename
        
        redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to

        ml = mail( :to => to_users,
          :cc => cc_users,
          :subject => new_title
        ) do |format|
          format.text { render plain: attachment.filename }
          format.html { render html: "#{attachment.filename}".html_safe }
        end
        return ml
      end
      
      #=========================================================
      # monkey patch for issue_add method of Mailer class
      #=========================================================
      def issue_add_with_attachments(issue, to_users, cc_users)
        prev_logger_lvl = set_logger_level
        Rails.logger.info "--- def issue_add_with_attachments ------"
        #------------------------------------------------------------
        # call original method
        #------------------------------------------------------------
        ml = issue_add_without_attachments(issue, to_users, cc_users)

        #------------------------------------------------------------
        # evaluate plugin settings
        #------------------------------------------------------------
        ps = retrieve_plugin_settings(issue)
        with_att = evaluate_attach_or_not(ps)
        
        # little bit tricky way, really work ... ?
        initialize
        #------------------------------------------------------------
        # attach all files on original notification mail
        #------------------------------------------------------------
        if ps.attach_all == true and with_att == true
          #unless Setting.plain_text_mail?
            issue.attachments.each do |attachment|
              Rails.logger.debug "***  att with notification: #{attachment.filename}"
              attachments[attachment.filename] = File.binread(attachment.diskfile)
            end
          #end
        end
        # plugin setting value: mail subject
        title = retrieve_and_eval_plugin_seting(issue, 'mail_subject')

        #-----------
        # mail
        #-----------
        ml = send_first_mail(to_users, cc_users, title, issue)
        
        #------------------------------------------------------------
        # send each files on dedicated mails
        #------------------------------------------------------------
        if ps.attach_all == false and with_att == true

          # send mail with attachments
          #unless Setting.plain_text_mail?
            issue.attachments.each do |attachment|
              Rails.logger.debug "***  att on dedicated mail: #{attachment.filename}"
              ml.deliver    # last deliver method will be called in caller - deliver_issue_edit method
              # plugin setting value: mail subject for attachment
              title2 = retrieve_and_eval_plugin_seting(issue, 'mail_subject_4_attachment', attachment:attachment)
              ml = send_with_dedicated_mail(to_users, cc_users, title2, attachment, issue)
            end
          #end
        end
        Rails.logger.level = prev_logger_lvl if prev_logger_lvl
      end

      #=========================================================
      # monkey patch for issue_edit method of Mailer class
      #=========================================================
      def issue_edit_with_attachments(journal, to_users, cc_users)
        prev_logger_lvl = set_logger_level
        Rails.logger.info "--- def issue_edit_with_attachments ------"
        #------------------------------------------------------------
        # call original method
        #------------------------------------------------------------
        ml = issue_edit_without_attachments(journal, to_users, cc_users)
        issue = journal.journalized

        #------------------------------------------------------------
        # evaluate plugin settings
        #------------------------------------------------------------
        ps = retrieve_plugin_settings(issue)
        with_att = evaluate_attach_or_not(ps)

        # little bit tricky way, really work ... ?
        initialize
        #------------------------------------------------------------
        # attach all files on original notification mail
        #------------------------------------------------------------
        if ps.attach_all == true and with_att == true
          #unless Setting.plain_text_mail?
            journal.details.each do |journal_detail|
              if journal_detail.property == 'attachment' && attachment = Attachment.find_by_id(journal_detail.prop_key)
                Rails.logger.debug "***  att with notification: #{attachment.filename}"
               attachments[attachment.filename] = File.binread(attachment.diskfile)
              end
            end
          #end
        end
        if journal.new_value_for('status_id')
          # plugin setting value: mail subject
         title = retrieve_and_eval_plugin_seting(issue, 'mail_subject', journal:journal)
        else
          # plugin setting value: mail subject without status
         title = retrieve_and_eval_plugin_seting(issue, 'mail_subject_wo_status', journal:journal)
        end
        #-----------
        # mail
        #-----------
        ml = send_first_mail(to_users, cc_users, title, issue)

        #------------------------------------------------------------
        # send each files on dedicated mails
        #------------------------------------------------------------
        if ps.attach_all == false and with_att == true

          # send mail with attachments
          #unless Setting.plain_text_mail?
            journal.details.each do |journal_detail|
              if journal_detail.property == 'attachment' && attachment = Attachment.find_by_id(journal_detail.prop_key)
                Rails.logger.debug "***  att on dedicated mail: #{attachment.filename}"
                ml.deliver    # last deliver method will be called in caller - deliver_issue_edit method
                # plugin setting value: mail subject for attachment
                title2 = retrieve_and_eval_plugin_seting(issue, 'mail_subject_4_attachment', attachment:attachment, journal:journal, journal_detail:journal_detail)
                ml = send_with_dedicated_mail(to_users, cc_users, title2, attachment, issue)
              end
            end
          #end
        end
        Rails.logger.level = prev_logger_lvl if prev_logger_lvl
      end
    end
  end
end

