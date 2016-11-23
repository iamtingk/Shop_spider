class CreateShops < ActiveRecord::Migration
  def change
    create_table :shops do |t|
      t.string :shop_name
      t.string :shop_lat
      t.string :shop_lng
      t.string :place_id
      t.string :address
      t.string :phone_number
      t.string :google_map_url
      t.string :website

      t.timestamps null: false
    end
  end
end
