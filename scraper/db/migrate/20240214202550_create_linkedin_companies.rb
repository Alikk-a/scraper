class CreateLinkedinCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :linkedin_companies do |t|
      t.string :link_company
      t.string :id_company
      t.string :search_by
      t.integer :attempts, default: 0
      t.string :name
      t.string :headquarters
      t.string :founded
      t.string :number_employees
      t.string :company_type
      t.string :website
      t.text :description

      t.timestamps

      t.index :id_company
    end
  end
end
