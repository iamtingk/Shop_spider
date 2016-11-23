class CreateShopImgs < ActiveRecord::Migration
  def change
    create_table :shop_imgs do |t|
      t.string :place_id
      t.string :shop_photo_reference

      t.timestamps null: false
    end
  end
end
