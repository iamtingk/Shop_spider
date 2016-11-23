class CreateShopTypes < ActiveRecord::Migration
  def change
    create_table :shop_types do |t|
      t.string :place_id
      t.string :shop_type

      t.timestamps null: false
    end
  end
end
