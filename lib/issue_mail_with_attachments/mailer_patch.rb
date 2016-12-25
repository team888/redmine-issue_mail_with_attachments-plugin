
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
        #------------------------------------------------------------
        # call original method
        #------------------------------------------------------------
        ml = issue_add_without_attachments(issue, to_users, cc_users)

        # plugin setting value: enable/disable file attachments
        with_att = Setting.plugin_issue_mail_with_attachments['enable_mail_attachments'].to_s.eql?('true') ? true : false
        # plugin setting value: attach all files on original notification mail
        attach_all = Setting.plugin_issue_mail_with_attachments['attach_all_to_notification'].to_s.eql?('true') ? true : false

        # little bit tricky way, really work ... ?
        initialize
        #------------------------------------------------------------
        # attach all files on original notification mail
        #------------------------------------------------------------
        if attach_all == true and with_att == true
          unless Setting.plain_text_mail?
            issue.attachments.each do |attachment|
              attachments[attachment.filename] = File.binread(attachment.diskfile)
            end
          end
        end
        # plugin setting value: mail subject
        s = Setting.plugin_issue_mail_with_attachments['mail_subject']
        s = eval("\"#{s}\"")
#        s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
        #-----------
        # mail
        #-----------
        # note: overwrite original mail method ... work ?
        ml = mail :to => to_users,
         :cc => cc_users,
         :subject => s

        #------------------------------------------------------------
        # send each files on dedicated mails
        #------------------------------------------------------------
        if attach_all == false and with_att == true
          # plugin setting value: mail subject for attachment
          ss = Setting.plugin_issue_mail_with_attachments['mail_subject_4_attachment']
          ss = eval("\"#{ss}\"")
#          ss = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] |att| "
          # send mail with attachments
          unless Setting.plain_text_mail?
            issue.attachments.each do |attachment|
              ml.deliver    # last deliver method will be called in caller - deliver_issue_edit method
              initialize
              attachments[attachment.filename] = File.binread(attachment.diskfile)
              sss = ss + attachment.filename
              #-----------
              # mail
              #-----------
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
      end

      #=========================================================
      # monkey patch for issue_edit method of Mailer class
      #=========================================================
      def issue_edit_with_attachments(journal, to_users, cc_users)
        #------------------------------------------------------------
        # call original method
        #------------------------------------------------------------
        ml = issue_edit_without_attachments(journal, to_users, cc_users)
        # plugin setting value: enable/disable file attachments
        with_att = Setting.plugin_issue_mail_with_attachments['enable_mail_attachments'].to_s.eql?('true') ? true : false
        # plugin setting value: attach all files on original notification mail
        attach_all = Setting.plugin_issue_mail_with_attachments['attach_all_to_notification'].to_s.eql?('true') ? true : false

        issue = journal.journalized
        # little bit tricky way, really work ... ?
        initialize
        #------------------------------------------------------------
        # attach all files on original notification mail
        #------------------------------------------------------------
        if attach_all == true and with_att == true
          unless Setting.plain_text_mail?
            journal.details.each do |detail|
              if detail.property == 'attachment' && attachment = Attachment.find_by_id(detail.prop_key)
                attachments[attachment.filename] = File.binread(attachment.diskfile)
              end
            end
          end
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
        ml = mail :to => to_users,
         :cc => cc_users,
         :subject => s
        #------------------------------------------------------------
        # send each files on dedicated mails
        #------------------------------------------------------------
        if attach_all == false and with_att == true
          # plugin setting value: mail subject for attachment
          ss = Setting.plugin_issue_mail_with_attachments['mail_subject_4_attachment']
          ss = eval("\"#{ss}\"")
#          ss = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] |att| "

          # send mail with attachments
          unless Setting.plain_text_mail?
            journal.details.each do |detail|
              if detail.property == 'attachment' && attachment = Attachment.find_by_id(detail.prop_key)
                ml.deliver    # last deliver method will be called in caller - deliver_issue_edit method
                # little bit tricky way, really work ... ?
                initialize
                attachments[attachment.filename] = File.binread(attachment.diskfile)
                sss = ss + attachment.filename
                #-----------
                # mail
                #-----------
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
        end
      end
    end
  end
end

