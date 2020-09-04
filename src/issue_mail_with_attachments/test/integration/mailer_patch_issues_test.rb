# Redmine - project management software
# Copyright (C) 2006-2017  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class MailerPatchIssuesTest < Redmine::IntegrationTest
  fixtures :projects,
           :users, :email_addresses,
           :roles,
           :members,
           :member_roles,
           :trackers,
           :projects_trackers,
           :enabled_modules,
           :issue_statuses,
           :issues,
           :enumerations,
           :custom_fields,
           :custom_values,
           :custom_fields_trackers,
           :attachments

  # add then remove 2 attachments to an issue
  def test_mailer_patch_issue_attachments
    ActionMailer::Base.deliveries.clear
    cf = IssueCustomField.generate!(:name => 'a Test Field', :field_format => 'bool', :is_for_all => true, :tracker_ids => Tracker.all.ids)
    cf.save
    log_user('jsmith', 'jsmith')
    set_tmp_attachments_directory
    
    plugin_settings = plugin_settings_init({
      :enable_mail_attachments => 'true',
      :attach_all_to_notification => 'false',
      :enable_project_level_control => 'true',
      :field_name_to_enable_att => 'a Test Field',
      
      :mail_subject => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject,
      :mail_subject_wo_status => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject_wo_status,
      :mail_subject_4_attachment => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject_4_attachment
    })
  
    # enable project module of plugin
    pj = Project.find(1)
    pj.enable_module!(:issue_mail_with_attachments_plugin)
    pj.save

    #===============
    # add
    #===============
    issue = nil
    files = []
    files << uploaded_test_file("2010/11/101123161450_testfile_1.png", "image/png")
    files << uploaded_test_file('iso8859-1.txt', 'text/plain')
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do

      issue = new_record(Issue) do
        post '/projects/ecookbook/issues', :params => {
            :issue => {
              :tracker_id => "1",
              :start_date => "2006-12-26",
              :priority_id => "4",
              :subject => "new test issue",
              :category_id => "",
              :description => "new issue",
              :done_ratio => "0",
              :due_date => "",
              :assigned_to_id => "",
              :custom_field_values => {cf.id => 1}
              },
            :attachments => {
              '1' => {'file' => files[0], 'description' => 'png file'},
              '2' => {'file' => files[1], 'description' => 'This is an attachment, iso8859-1.txt'}
            }
          }
      end
        
    end
    # check redirection
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue
    follow_redirect!

    # check issue attributes
    assert_equal 'jsmith', issue.author.login
    assert_equal 1, issue.project.id
    assert_equal 1, issue.status.id

    atts = []
    atts <<  Attachment.new(:file => files[0])
    atts <<  Attachment.new(:file => files[1])
    assert_sent_with_dedicated_mails num_att_mails:2, atts:atts, issue:Issue.find(issue.id), title_wo_status:false, recipients:["jsmith@somenet.foo", "dlopper@somenet.foo"]

    #===============
    # edit
    #===============
    ActionMailer::Base.deliveries.clear
    
    with_settings( {:notified_events => %w(issue_added issue_updated),
      :plugin_issue_mail_with_attachments => plugin_settings
    }) do

      attachments = new_records(Attachment, 2) do
        put '/issues/' + issue.id.to_s, :params => {
            :issue => {:notes => 'Some notes', :custom_field_values => {cf.id => 1}},
            :attachments => {
              '1' => {'file' => uploaded_test_file("japanese-utf-8.txt", "text/plain"), 'description' => 'jpn file'},
              '2' => {'file' => uploaded_test_file('testfile.txt', 'text/plain'), 'description' => 'This is an attachment'}
            }
          }
        assert_redirected_to "/issues/" + issue.id.to_s
      end

      assert_equal Issue.find(issue.id), attachments[1].container
      assert_equal 'testfile.txt', attachments[1].filename
      assert_equal 'This is an attachment', attachments[1].description
      # verify the size of the attachment stored in db
      #assert_equal file_data_1.length, attachment.filesize
      # verify that the attachment was written to disk
      assert File.exist?(attachments[1].diskfile)
      
      assert_sent_with_dedicated_mails num_att_mails:2, atts:attachments, issue:Issue.find(issue.id), title_wo_status:true, recipients:["jsmith@somenet.foo", "dlopper@somenet.foo"]
    end
    
    # remove the attachments
    Issue.find(issue.id).attachments.each(&:destroy)
    assert_equal 0, Issue.find(issue.id).attachments.length
  end

end
