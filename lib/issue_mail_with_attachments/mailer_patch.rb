
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
        Rails.logger.debug "def issue_add_with_attachments"
        #------------------------------------------------------------
        # call original method
        #------------------------------------------------------------
        ml = issue_add_without_attachments(issue, to_users, cc_users)

        # plugin setting value: enable/disable file attachments
        with_att = Setting.plugin_issue_mail_with_attachments['enable_mail_attachments'].to_s.eql?('true') ? true : false
        # plugin setting value: attach all files on original notification mail
        attach_all = Setting.plugin_issue_mail_with_attachments['attach_all_to_notification'].to_s.eql?('true') ? true : false
        # plugin setting value: only attach for specified projects
        project_map = Setting.plugin_issue_mail_with_attachments['attach_only_for_project'].to_s.split(",").map { |s| s.to_i }
        project_att = project_map.include?(issue.project_id)
        if !project_map.empty? and project_att == false 
          with_att = false
        end
        Rails.logger.debug "  with_att:#{with_att}, attach_all: #{attach_all}"
        
        # little bit tricky way, really work ... ?
        initialize
        #------------------------------------------------------------
        # attach all files on original notification mail
        #------------------------------------------------------------
        if attach_all == true and with_att == true
          #unless Setting.plain_text_mail?
            issue.attachments.each do |attachment|
              Rails.logger.debug "  att with notification: #{attachment.filename}"
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
              Rails.logger.debug "  att with notification: #{attachment.filename}"
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
        Rails.logger.debug "def issue_edit_with_attachments"
        #------------------------------------------------------------
        # call original method
        #------------------------------------------------------------
        ml = issue_edit_without_attachments(journal, to_users, cc_users)
        # plugin setting value: enable/disable file attachments
        with_att = Setting.plugin_issue_mail_with_attachments['enable_mail_attachments'].to_s.eql?('true') ? true : false
        # plugin setting value: attach all files on original notification mail
        attach_all = Setting.plugin_issue_mail_with_attachments['attach_all_to_notification'].to_s.eql?('true') ? true : false
        # plugin setting value: only attach for specified projects
        project_map = Setting.plugin_issue_mail_with_attachments['attach_only_for_project'].to_s.split(",").map { |s| s.to_i }
        project_att = project_map.include?(journal.issue.project_id)
        if !project_map.empty? and project_att == false 
          with_att = false
        end
        Rails.logger.debug "  with_att:#{with_att}, attach_all: #{attach_all}"

        issue = journal.journalized
        # little bit tricky way, really work ... ?
        initialize
        #------------------------------------------------------------
        # attach all files on original notification mail
        #------------------------------------------------------------
        if attach_all == true and with_att == true
          #unless Setting.plain_text_mail?
            journal.details.each do |detail|
              if detail.property == 'attachment' && attachment = Attachment.find_by_id(detail.prop_key)
                Rails.logger.debug "  att with notification: #{attachment.filename}"
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
                Rails.logger.debug "  att with dedicate mail: #{attachment.filename}"
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

