
require File.expand_path('../../test_helper', __FILE__)
require 'csv'
require "issue_mail_with_attachments/mailer_patch.rb"

class MailPatchAddTest < ActiveSupport::TestCase

def test_evaluate_attach_or_not_pairwise_comb_4

  CSV.foreach(File.expand_path('../../pictresult.csv', __FILE__), headers: true) do |d|
    ps = IssueMailWithAttachments::MailerPatch::InstanceMethods::PluginSettings.new
#    ps = Mailer::InstanceMethods::PluginSettings.new
    ps.att_enabled = d["att_enabled"].nil? ? nil: d["att_enabled"] == 'true'? true: false
    ps.attach_all = d["attach_all"].nil? ? nil: d["att_enabled"] == 'true'? true: false
    ps.prj_ctl_enabled = d["prj_ctl_enabled"].nil? ? nil: d["att_enabled"] == 'true'? true: false
    ps.mod_enabled = d["mod_enabled"].nil? ? nil: d["att_enabled"] == 'true'? true: false
    ps.cf_name_for_issue = d["cf_name_for_issue"]
    ps.enabled_for_issue = d["enabled_for_issue"].nil? ? nil: d["att_enabled"] == 'true'? true: false
    expected = d["result"].nil? ? nil: d["att_enabled"] == 'true'? true: false
    actual = IssueMailWithAttachments::MailerPatch::InstanceMethods.evaluate_attach_or_not(ps)
    assert_equal expected, actual
  end
end  

end
