
#Ruby on Rails - 商店爬蟲


這是利用Google Places API作為區域性的商店爬蟲
只要是google api釋出的商家，都可以採集


##Setup：
```
$ https://github.com/iamtingk/Shop_spider.git

$ cd Shop_spider

$ bundle install
```


Google API Console(https://console.developers.google.com)Google 開啟Places API Web Service
申請一組憑證後
gps_run_controller.rb：
```
$google_key = "google_api_key"
```

記得啟動mysql
編輯config/database.yml
改成自己的資料庫
終端機：
```
$ rake db:create

$ rake db:migrate
```


google API有限制連接次數 15萬次/天 
故程式初始數值可設置連接次數
gps_run_controller.rb：
```
* connect_total = 10000#最大連接數
```

可初始圓的搜尋範圍
gps_run_controller.rb：
```
radius=150#大圓
```



可初始最初座標、終點座標
gps_run_controller.rb：
```
/#台中座標
min_x = 120.461443 #起始x
min_y = 24.447581 #起始y
max_x = 121.451586 #終點x
max_y = 24.009268 #終點y

#最左上為起始點
#最右下為終點
#此範圍可以設置台中市、台南市、整個台灣
```

啟動
```
$ rails server
```


開啟瀏覽器，輸入：localhost:3000/run
直接運行，運行的狀態會在終端機顯示


##特色：
我的方式
```
最左上為起始，最右下為終點
跑的路線是
由左往右跑完 -> 
往下一個距離點 -> 
再次由左往右跑 -> 
```


* 到達設置的終點座標，會自動結束程式


* 到達設置的連接次數，會自動結束程式


* 超過google連接額度，會自動結束程式


>萬一遇到需停止程式的因素但還未採集完畢，這時候程式會記錄當前座標，以利下次執行程式時，繼續以已記錄的座標為起始點來運行
>註：當前座標會記錄在gpsrun.txt


如下圖：


![gpsrun.txt](https://github.com/iamtingk/Shop_spider/blob/master/pic/14233.png)
</br>
</br>
</br>
</br>
>google api取得的place_id是商店的唯一值，程式以此place_id判斷該筆資訊是否重複，以十萬筆為例，我用file方式比對，與mysql比較起來，file方式的比對速度快很多
>註：未重複的place_id會記錄在check_place.txt


如下圖：


![check_place](https://github.com/iamtingk/Shop_spider/blob/master/pic/14234.png)





##採集資訊
判斷該資訊的郵遞區號，來正確區分縣市
儲存的資訊有：
```
商家名稱
經緯度
place_id
地址
電話
地圖連結
網站
圖片連結
營業時間
商家型態
```



##自動產出檔案
初始化座標，記得直接刪除check_place.txt、gpsrun.txt、select_gps.txt這三個檔案，程式會自動再次產出
```
check_place.txt ： 比對place_id是否重複
gpsrun.txt      ： 記錄當前爬蟲座標
select_gps.txt  ： 記錄運行次數
```

##資料庫結構
```
Shop
|____shop_name
|____shop_lat
|____shop_lng
|____place_id
|____address
|____phone_number
|____google_map_url
|____website

Shop_place_countie
|____place_id
|____place_county
|____place_zip_code

Shop_img
|____place_id
|____shop_photo_reference

Shop_time
|____place_id
|____time_mon
|____time_tue
|____time_wed
|____time_thu
|____time_fri
|____time_sat
|____time_sun

Shop_type
|____place_id
|____shop_type
```


###development環境，可正常運行
###我習慣運用nginx+unicorn實行production環境


以終端機觀看爬蟲訊息，運行狀況

如下圖：




![運行1](https://github.com/iamtingk/Shop_spider/blob/master/pic/14231.png)
</br>
</br>
</br>
![運行2](https://github.com/iamtingk/Shop_spider/blob/master/pic/14232.png)
</br>
</br>
</br>

##聯絡我
如果需改進的地方或是交流，很歡迎來信：
```
gntim0o01@gmail.com
```
</br>
</br>
