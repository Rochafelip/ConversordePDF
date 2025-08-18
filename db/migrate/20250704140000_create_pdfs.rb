class CreatePdfs < ActiveRecord::Migration[7.1]
  def change
    create_table :pdfs do |t|
      t.string :nome_arquivo

      t.timestamps
    end
  end
end
