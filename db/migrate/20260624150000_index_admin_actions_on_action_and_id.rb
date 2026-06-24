class IndexAdminActionsOnActionAndId < ActiveRecord::Migration[8.1]
  def change
    # (action, id) backs the log's category filter + keyset pagination in one
    # index: WHERE action IN (...) AND id < ? ORDER BY id DESC. A single-value
    # filter is fully index-ordered; a multi-action category (IN) still needs a
    # sort, but bounded by the category's size — fine at staff-action volume.
    # actor_id already has its own index from the t.references. Writes are rare
    # (staff actions), so the extra index costs nothing meaningful.
    add_index :admin_actions, [ :action, :id ]
  end
end
