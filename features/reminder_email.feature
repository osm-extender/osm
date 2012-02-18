@reminder_email
@reminder_email_item
@email
@osm

Feature: Reminder Email
    As asection leader
    In order to keep on top of what's happening with my section
    I want to be reminded by email of key information on a weekly basis
    And I want to control which day the email is sent
    And I want to be able to edit the configuration of each part of the email

    Background:
	Given I have no users
        And I have the following user records
	    | email_address     | name  |
	    | alice@example.com | Alice |
        And "alice@example.com" is an activated user account
	And "alice@example.com" is connected to OSM
	And an OSM request to "get roles" will give 1 role
	And no emails have been sent


    Scenario: Add reminder email
        When I signin as "alice@example.com" with password "P@55word"
        And I follow "Email reminders"
        And I follow "New reminder"
        And I select "Tuesday" from "Send on"
        And I press "Create Email reminder"
        Then I should see "successfully created"
        And I should see "now add some items to your reminder"
        And I should see "Tuesday"
        And "alice@example.com" should have 1 email reminder

    Scenario: Add birthday item to reminder email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        When I signin as "alice@example.com" with password "P@55word"
        And I go to the list of email_reminders
        And I follow "[Edit]" in the "Actions" column of the "Tuesday" row
        And I follow "Birthdays"
        And I fill in "How many months into the past?" with "3"
        And I fill in "How many months into the future?" with "4"
        And I press "Create Email reminder item birthday"
        Then I should see "Item was successfully added"
        And I should see "How many months into the past?: 3" in the "Configuration" column of the "Birthdays" row
        And I should see "How many months into the future?: 4" in the "Configuration" column of the "Birthdays" row

    Scenario: Add event item to reminder email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        When I signin as "alice@example.com" with password "P@55word"
        And I go to the list of email_reminders
        And I follow "[Edit]" in the "Actions" column of the "Tuesday" row
        And I follow "Events"
        And I fill in "How many months into the future?" with "6"
        And I press "Create Email reminder item event"
        Then I should see "Item was successfully added"
        And I should see "How many months into the future?: 6" in the "Configuration" column of the "Events" row

    Scenario: Add programme item to reminder email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        When I signin as "alice@example.com" with password "P@55word"
        And I go to the list of email_reminders
        And I follow "[Edit]" in the "Actions" column of the "Tuesday" row
        And I follow "Programme"
        And I fill in "How many weeks into the future?" with "8"
        And I press "Create Email reminder item programme"
        Then I should see "Item was successfully added"
        And I should see "How many weeks into the future?: 8" in the "Configuration" column of the "Programme" row

    Scenario: Add not seen item to reminder email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        When I signin as "alice@example.com" with password "P@55word"
        And I go to the list of email_reminders
        And I follow "[Edit]" in the "Actions" column of the "Tuesday" row
        And I follow "Member not seen"
        And I fill in "For how many weeks?" with "1"
        And I press "Create Email reminder item not seen"
        Then I should see "Item was successfully added"
        And I should see "For how many weeks?: 1" in the "Configuration" column of the "Members not seen" row

    Scenario: Add due badge item to reminder email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        When I signin as "alice@example.com" with password "P@55word"
        And I go to the list of email_reminders
        And I follow "[Edit]" in the "Actions" column of the "Tuesday" row
        And I follow "Due badges"
        And I press "Create Email reminder item due badge"
        Then I should see "Item was successfully added"
        And I should see "Due badges"


    Scenario: Edit reminder email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        When I signin as "alice@example.com" with password "P@55word"
        And I go to the list of email_reminders
        And I follow "[Edit]" in the "Actions" column of the "Tuesday" row
        And I select "Wednesday" from "Send on"
        And I press "Update Email reminder"
        Then I should see "successfully updated"
        And I should see "Wednesday"

    Scenario: Edit birthday item in reminder email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        And "alice@example.com" has a birthday item in her "Tuesday" email reminder for section 1
        When I signin as "alice@example.com" with password "P@55word"
        And I go to the list of email_reminders
        And I follow "[Edit]" in the "Actions" column of the "Tuesday" row
        And I follow "[Edit]" in the "Actions" column of the "Birthdays" row
        And I fill in "How many months into the past?" with "3"
        And I fill in "How many months into the future?" with "4"
        And I press "Update Email reminder item birthday"
        Then I should see "Item was successfully updated"
        And I should see "How many months into the past?: 3" in the "Configuration" column of the "Birthdays" row
        And I should see "How many months into the future?: 4" in the "Configuration" column of the "Birthdays" row

    Scenario: Edit event item in reminder email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        And "alice@example.com" has an event item in her "Tuesday" email reminder for section 1
        When I signin as "alice@example.com" with password "P@55word"
        And I go to the list of email_reminders
        And I follow "[Edit]" in the "Actions" column of the "Tuesday" row
        And I follow "[Edit]" in the "Actions" column of the "Events" row
        And I fill in "How many months into the future?" with "6"
        And I press "Update Email reminder item event"
        Then I should see "Item was successfully updated"
        And I should see "How many months into the future?: 6" in the "Configuration" column of the "Events" row

    Scenario: Edit programme item in reminder email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        And "alice@example.com" has a programme item in her "Tuesday" email reminder for section 1
        When I signin as "alice@example.com" with password "P@55word"
        And I go to the list of email_reminders
        And I follow "[Edit]" in the "Actions" column of the "Tuesday" row
        And I follow "[Edit]" in the "Actions" column of the "Programme" row
        And I fill in "How many weeks into the future?" with "8"
        And I press "Update Email reminder item programme"
        Then I should see "Item was successfully updated"
        And I should see "How many weeks into the future?: 8" in the "Configuration" column of the "Programme" row

    Scenario: Edit not seen item in reminder email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        And "alice@example.com" has a not seen item in her "Tuesday" email reminder for section 1
        When I signin as "alice@example.com" with password "P@55word"
        And I go to the list of email_reminders
        And I follow "[Edit]" in the "Actions" column of the "Tuesday" row
        And I follow "[Edit]" in the "Actions" column of the "Members not seen" row
        And I fill in "For how many weeks?" with "1"
        And I press "Update Email reminder item not seen"
        Then I should see "Item was successfully updated"
        And I should see "For how many weeks?: 1" in the "Configuration" column of the "Members not seen" row

    Scenario: Edit due badge item in reminder email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        And "alice@example.com" has a due badge item in her "Tuesday" email reminder for section 1
        When I signin as "alice@example.com" with password "P@55word"
        And I go to the list of email_reminders
        And I follow "[Edit]" in the "Actions" column of the "Tuesday" row
        And I follow "[Edit]" in the "Actions" column of the "Due badges" row
        And I press "Update Email reminder item due badge"
        Then I should see "Item was successfully updated"
        And I should see "Due badges"


    Scenario: Send the email
        Given "alice@example.com" has a reminder email for section 1 on "Tuesday"
        And "alice@example.com" has a birthday item in her "Tuesday" email reminder for section 1
        And "alice@example.com" has an event item in her "Tuesday" email reminder for section 1
        And "alice@example.com" has a programme item in her "Tuesday" email reminder for section 1
        And "alice@example.com" has a not seen item in her "Tuesday" email reminder for section 1
        And "alice@example.com" has a due badge item in her "Tuesday" email reminder for section 1
	And an OSM request to get terms for section 1 will have the term
	    | term_id | name   |
	    | 1       | Term 1 |
	And an OSM request to get members for section 1 in term 1 will have the members
	    | email1         | email2         | email3         | email4         | grouping_id |
	    | a1@example.com | a2@example.com | a3@example.com | a4@example.com | 1           |
	    | b1@example.com | b2@example.com | b3@example.com | b4@example.com | 2           |
	And an OSM request to get events for section 1 will have the events
	    | name    | in how many days |
	    | Event 1 | 7                |
	    | Event 2 | 300              |
	And an OSM request to get programme for section 1 term 1 will have 2 programme items
	And an OSM request to get activity 11 will have tags "global"
	And an OSM request to get activity 12 will have tags "outdoors"
	And an OSM request to get activity 21 will have tags "belief, values"
	And an OSM request to get activity 22 will have tags "global, outdoors"
	And an OSM request to get the register structure for term 1 and section 1 will cover the last 4 weeks
	And an OSM request to get the register for term 1 and section 1 will have the following members and attendance
	    | name  | from weeks ago | to weeks ago |
	    | Alice | 4              | 1            |
	    | Bob   | 4              | 3            |
	And an OSM request to get due badges for section 1 and term 1 will result in the following being due their "Test" badge
	    | name  | completed | extra |
	    | Alice | 4         | info  |
	    | Bob   | 5         |       |

        When "alice@example.com"'s reminder email for section 1 on "Tuesday" is sent
        Then "alice@example.com" should receive 1 email with subject /Reminder/

        When "alice@example.com" opens the email with subject /Reminder/
        Then I should see "Birthdays" in the email body
        And I should see "Due Badges" in the email body
        And I should see "Events" in the email body
        And I should see "Programme" in the email body
        And I should see "Members Not Seen" in the email body