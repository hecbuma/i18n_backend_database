class CreateI18nTables < ActiveRecord::Migration
  def change
    create_table :locales do |t|
      t.string   :code
      t.string   :name
    end
    add_index :locales, :code

    create_table :translations do |t|
      t.string   :key
      t.text     :raw_key
      t.text     :value
      t.integer  :pluralization_index, :default => 1
      t.integer  :locale_id
    end
    add_index :translations, [:locale_id, :key, :pluralization_index]

  end
end
