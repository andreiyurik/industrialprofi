class AddUserToLessonSuggestions < ActiveRecord::Migration[8.1]
  # Bind a suggestion to the ACCOUNT that made it, not just a display name.
  # Identity is the unit the track record is computed over: without it, two
  # edits by the same person are indistinguishable and no history can accrue.
  # Nullable on purpose — legacy/anonymous suggestions keep their author_name
  # and simply carry no track record.
  def up
    add_reference :lesson_suggestions, :user, null: true, foreign_key: true
    backfill_user_ids
  end

  def down
    remove_reference :lesson_suggestions, :user, foreign_key: true
  end

  private
    # Reconnect historical suggestions to accounts so past contributors get
    # credit. Match on contact email first (exact, unique), then on an
    # unambiguous display-name match. Anything ambiguous stays anonymous — we
    # never GUESS an identity into the record.
    def backfill_user_ids
      say_with_time "Backfilling lesson_suggestions.user_id" do
        matched = 0
        LessonSuggestion.reset_column_information

        LessonSuggestion.where(user_id: nil).find_each do |suggestion|
          user = user_for(suggestion)
          next unless user

          suggestion.update_columns(user_id: user.id)
          matched += 1
        end
        matched
      end
    end

    def user_for(suggestion)
      by_email = suggestion.author_contact.presence &&
        User.where(email_address: suggestion.author_contact.strip.downcase).first
      return by_email if by_email

      by_name = User.where(name: suggestion.author_name)
      by_name.first if by_name.count == 1
    end
end
