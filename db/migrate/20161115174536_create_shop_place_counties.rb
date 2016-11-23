class CreateShopPlaceCounties < ActiveRecord::Migration
  def change
    create_table :shop_place_counties do |t|
      t.string :place_id
      t.string :place_county
      t.string :place_zip_code

      t.timestamps null: false
    end
  end
end
