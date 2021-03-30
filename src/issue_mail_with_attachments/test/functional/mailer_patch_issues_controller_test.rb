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

#if Redmine::VERSION::MAJOR >= 3 and Redmine::VERSION::MINOR >= 4

  class IssuesControllerTest < Redmine::ControllerTest
    fixtures :projects,
             :users, :email_addresses, :user_preferences,
             :roles,
             :members,
             :member_roles,
             :issues,
             :issue_statuses,
             :issue_relations,
             :versions,
             :trackers,
             :projects_trackers,
             :issue_categories,
             :enabled_modules,
             :enumerations,
             :attachments,
             :workflows,
             :custom_fields,
             :custom_values,
             :custom_fields_projects,
             :custom_fields_trackers,
             :time_entries,
             :journals,
             :journal_details,
             :queries,
             :repositories,
             :changesets

    include Redmine::I18n

    def setup
      User.current = nil
    end

    def test_mailer_patch_post_create_with_attachment
      ActionMailer::Base.deliveries.clear
      set_tmp_attachments_directory
      @request.session[:user_id] = 2

      plugin_settings = plugin_settings_init({
        :enable_mail_attachments => 'true',
        :attach_all_to_notification => 'false',

        :mail_subject => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject,
        :mail_subject_wo_status => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject_wo_status,
        :mail_subject_4_attachment => IssueMailWithAttPluginInfo::DEFAULT_edit_mail_subject_4_attachment
      })

      with_settings( {:notified_events => %w(issue_added),
        :plugin_issue_mail_with_attachments => plugin_settings
      }) do
        assert_difference 'Issue.count' do
          post :create, :params => {
              :project_id => 1,
              :issue => {
                :tracker_id => '1',
                :subject => 'With attachment' 
              },  
              :attachments => {
                '1' => {
                  'file' => uploaded_test_file('testfile.txt', 'text/plain'), 'description' => 'test file'},
                '2' => {
                  'file' => uploaded_test_file("2010/11/101123161450_testfile_1.png", "image/png"), 'description' => 'png file'} 
              }
            }
        end
        atts = []
        a = Attachment.new(filename:'testfile.txt')
        atts << a
        a = Attachment.new(filename:'101123161450_testfile_1.png')
        atts << a
        issue = Issue.order('id DESC').first
        assert_sent_with_dedicated_mails num_att_mails:2, issue:issue, atts:atts, recipients:["jsmith@somenet.foo", "dlopper@somenet.foo"]

        attachment = Attachment.order('id DESC')[1]
        assert_equal issue, attachment.container
        assert_equal 2, attachment.author_id
        assert_equal 'testfile.txt', attachment.filename
        assert_equal 'text/plain', attachment.content_type
        assert_equal 'test file', attachment.description
        assert_equal 59, attachment.filesize
        assert File.exists?(attachment.diskfile)
        assert_equal 59, File.size(attachment.diskfile)
      end
    end

  end
