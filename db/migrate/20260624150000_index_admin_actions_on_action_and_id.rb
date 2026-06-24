class IndexAdminActionsOnActionAndId < ActiveRecord::Migration[8.1]
  def change
    # (action, id) backs the log's category filter + keyset pagination in one
    # index: WHERE action IN (...) AND id < ? ORDER BY id DESC. actor_id already
    # has its own index from the t.references. Writes are rare (staff actions),
    # so the extra index costs nothing meaningful.
    add_index :admin_actions, [ :action, :id ]
  end
end
