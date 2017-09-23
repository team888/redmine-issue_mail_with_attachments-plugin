# Redmine issue_mail_with_attachments plugin

With this plugin, you can send out newly attached files on issues via usual issue notification mails or dedicated mails as attachments.

## Installation
1. Copy extracted plugin folder to redmine's plugins folder.
2. Rename copied plugin folder to "issue_mail_with_attachments".
3. Restart your Redmine servers.

## Setup
1. Login to your redmine with admin privilege account.
2. Open \[Administration] > [Plugins], click [Configure] link on [Issue Mail With Attachments plugin].
3. Set configuration items as you want. Besides attachment settings such as enable/disable, advanced user can optionally change mail subject string by modifying template definition here.

Configuration UI
![UI image](ui.png "UI image")

Chinese Configuration UI
![Chinese UI image](ui-zh.png "Chinese UI image")

Japanese Configuration UI
![Japanese UI image](ui-ja.png "Japanese UI image")

## Usage
1. Manipulate Redmine issues as usual, issue attachment files are sent out with notification mails at the time of issue creation and update.

## Compatibility
Redmine 2.6 to 3.4 ( checked on 2.6, 3.3 and 3.4.2 so far )