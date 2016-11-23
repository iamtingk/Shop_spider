class CreateShopTimes < ActiveRecord::Migration
  def change
    create_table :shop_times do |t|
      t.string :place_id
      t.string :time_mon
      t.string :time_tue
      t.string :time_wed
      t.string :time_thu
      t.string :time_fri
      t.string :time_sat
      t.string :time_sun

      t.timestamps null: false
    end
  end
end
