Feature: My Account
    As a user of the site
    In order to manage my account
    I want to edit my account
    And know that no one else can edit it
    And know that no one else can view it


    Scenario: View Details
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
	    | bob@example.com   | Bob%1234 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the my account page
        Then I should see "alice@example.com"
        And I should not see "bob@example.com"
	And I should be on the my_account page

    Scenario: View Details (not signed in)
	When I go to the my account page
	Then I should see "You must be signed in"
	And I should be on the signin page


    Scenario: Edit Details
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
	    | bob@example.com   | Bob%1234 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the edit my account page
	And I fill in "Email address" with "alice2@example.com"
	And I fill in "Name" with "Alice2"
	And I press "Save changes"
        Then I should see "Sucessfully updated your details."
	And I should see "alice2@example.com"
	And I should see "Alice2"
	And I should be on the my_account page

    Scenario: Edit Details (not signed in)
	When I go to the edit my account page
	Then I should see "You must be signed in"
	And I should be on the signin page

    Scenario: Edit Details (blank email address)
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the edit my account page
	And I fill in "Email address" with ""
	And I press "Save changes"
        Then I should see "Email address can't be blank"
	And I should be on the update_my_account page

    Scenario: Edit Details (bad email address)
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the edit my account page
	And I fill in "Email address" with "a"
	And I press "Save changes"
        Then I should see "does not look like an email address"
	And I should be on the update_my_account page

    Scenario: Edit Details (existing email address)
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
	    | bob@example.com   | Bob%^123 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the edit my account page
	And I fill in "Email address" with "bob@example.com"
	And I press "Save changes"
        Then I should see "Email address has already been taken"
	And I should be on the update_my_account page

    Scenario: Edit details (blank name)
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the edit my account page
	And I fill in "Name" with ""
	And I press "Save changes"
        Then I should see "Name can't be blank"
	And I should be on the update_my_account page

    
    Scenario: Change Password
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the change my password page
	And I fill in "Current password" with "Alice%12"
	And I fill in "New password" with "aA1&1234"
	And I fill in "New password confirmation" with "aA1&1234"
	And I press "Change password"
	Then I should see "Sucessfully changed your password."
	And I should be on the my_account page

    Scenario: Change Password (not signed in)
	When I go to the change my password page
	Then I should see "You must be signed in"
	And I should be on the signin page

    Scenario: Change Password (too short)
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the change my password page
	And I fill in "Current password" with "Alice%12"
	And I fill in "New password" with "a"
	And I fill in "New password confirmation" with "a"
	And I press "Change password"
	Then I should see "Password is too short"
	And I should be on the update_my_password page

    Scenario: Change Password (too easy)
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the change my password page
	And I fill in "Current password" with "Alice%12"
	And I fill in "New password" with "aaaaaaaa"
	And I fill in "New password confirmation" with "aaaaaaaa"
	And I press "Change password"
	Then I should see "Password does not use at least 2 different types of character"
	And I should be on the update_my_password page

    Scenario: Change Password (no confirmation)
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the change my password page
	And I fill in "Current password" with "Alice%12"
	And I fill in "New password" with "aA1&1234"
	And I press "Change password"
	Then I should see "Password confirmation does not match"
	And I should be on the update_my_password page

    Scenario: Change Password (incorrect confirmation)
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the change my password page
	And I fill in "Current password" with "Alice%12"
	And I fill in "New password" with "aA1&1234"
	And I fill in "New password confirmation" with "abcdefgh"
	And I press "Change password"
	Then I should see "Password confirmation does not match"
	And I should be on the update_my_password page

    Scenario: Change Password (incorrect current password)
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the change my password page
	And I fill in "Current password" with "wrong password"
	And I fill in "New password" with "aA1&1234"
	And I fill in "New password confirmation" with "aA1&1234"
	And I press "Change password"
	Then I should see "Incorrect current password."
	And I should be on the update_my_password page

    Scenario: Change Password (password is email address)
        Given I have the following user records
	    | email_address     | password |
	    | alice@example.com | Alice%12 |
        And "alice@example.com" is an activated account
        When I signin as "alice@example.com" with password "Alice%12"
        And I go to the change my password page
	And I fill in "Current password" with "Alice%12"
	And I fill in "New password" with "alice@example.com"
	And I fill in "New password confirmation" with "alice@example.com"
	And I press "Change password"
	Then I should see "Password is not allowed to be your email address"
	And I should be on the update_my_password page