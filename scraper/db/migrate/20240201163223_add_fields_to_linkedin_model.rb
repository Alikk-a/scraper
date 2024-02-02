class AddFieldsToLinkedinModel < ActiveRecord::Migration[7.0]
  def change
    add_column :linkedins, :type_job, :string
    add_column :linkedins, :location, :string

  end
end
