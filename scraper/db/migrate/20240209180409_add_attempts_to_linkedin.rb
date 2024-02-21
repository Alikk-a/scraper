class AddAttemptsToLinkedin < ActiveRecord::Migration[7.0]
  def change
    add_column :linkedins, :attempts, :integer, default: 0
  end
end
