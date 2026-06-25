class AddSuspendedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    # nil = active. A timestamp = suspended (a reversible ban): login is blocked
    # and all sessions are revoked, but the account and its history are kept, so
    # an administrator can reinstate it. Distinct from account deletion.
    add_column :users, :suspended_at, :datetime
  end
end
