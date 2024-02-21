class CreateLinkedinPeople < ActiveRecord::Migration[7.0]
  def change
    create_table :linkedin_people do |t|
      t.string :link_person
      t.string :id_person
      t.string :search_by
      t.integer :attempts, default: 0
      t.string :name
      t.string :subtitle
      t.string :location
      t.text :description

      t.timestamps

      t.index :id_person
    end
  end
end
