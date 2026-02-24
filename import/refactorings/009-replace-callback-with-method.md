# Refactoring: Replace Callback with Method

## Context
An ActiveRecord callback (`after_create`, `after_save`, etc.) that performs
work unrelated to the record's own persistence — sending email, creating records
in other models, calling external services. The side effect is invisible to the
caller and fires even when triggered by unrelated saves.

See also: `coding-classic.md § Callbacks` for when callbacks are appropriate
(own-state changes, async dispatch via jobs).

## Before
```ruby
class Invitation < ApplicationRecord
  after_create :deliver

  private

  def deliver
    InvitationMailer.invite(self).deliver_later
  end
end

# Caller has no visibility into delivery:
Invitation.create!(email: email, survey: survey)
```

## After
```ruby
class Invitation < ApplicationRecord
  # No callback — deliver is a public method, called explicitly
  def deliver
    InvitationMailer.invite(self).deliver_later
  end
end

class SurveyInviter
  def create_and_deliver_invitations
    invitations = parsed_emails.map do |email|
      Invitation.create!(email: email, survey: @survey)
    end
    invitations.each(&:deliver)
  end
end
```

## Why
Delivery is visible at the call site. If a `create!` fails mid-loop, no emails
are sent for records that don't exist yet. The callback can't be accidentally
triggered by an unrelated `save` elsewhere. Delivery is testable without
persistence side effects.

## When NOT to apply
- The callback updates derived state on the same record (`before_save :normalize_email`,
  `before_save :update_search_index, if: :title_changed?`) — own-state
  management is the right use of callbacks.
- The callback dispatches to a background job (`after_create_commit :notify_later`)
  — async dispatch is an acceptable callback use; the job itself should be thin.

_[Ruby Science →](https://thoughtbot.com/ruby-science/replace-callback-with-method.html)_
