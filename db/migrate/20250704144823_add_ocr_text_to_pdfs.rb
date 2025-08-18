class AddOcrTextToPdfs < ActiveRecord::Migration[7.1]
  def change
    add_column :pdfs, :ocr_text, :text
  end
end
