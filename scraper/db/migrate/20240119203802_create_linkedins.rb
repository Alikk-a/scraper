class CreateLinkedins < ActiveRecord::Migration[7.0]
  def change
    create_table :linkedins do |t|
      t.string :link_job
      t.string :linkedin_id_job
      t.string :title
      t.text :description
      t.datetime :posted_at

      t.timestamps

      t.index :linkedin_id_job
    end
  end
end
