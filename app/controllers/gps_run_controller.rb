class GpsRunController < ApplicationController
  def run

    #計數區
    @count_run_re = 0#初始place_id重複數(搜到的總店家（含重複）)
    @count_run_no_re = 0#初始place_id非重複數
    connect_count = 0#初始連接數
    connect_total = 10000#最大連接數
    over_query_limit_now = 0# 1表示超過API查詢額度
    $isBreak=true#連接take_shop_data用的狀態判斷
    #true=>正常傳輸，false=>超過額度



    

    #狀態
    status_code=0 
    #0=> 初始化
    #1=> min_x < max_x|min_y < max_y
    #2=> min_x > max_x|min_y < max_y
    #3=> min_x < max_x|min_y > max_y
    #4=> min_x > max_x|min_y > max_y
    
    
    #方圓距離
    # 以150方圓跑120方圓的範圍=>以正方形的涵蓋形式來爬取
    radius=150#大圓
    circle=120#小圓（未精算）
    mtolonlat = 0.000009#公尺=>經緯度
    distance = (circle*mtolonlat)# distance=>0.00108

    #key
    $google_key = "google_api_key"
    



    #台中座標
    # min_x = 120.461443#起始min_x
    # min_y = 24.447581#起始min_y
    # max_x = 121.451586#結束max_x
    # max_y = 24.009268#結束max_y

    #豐原市區座標
    min_x = 120.696629#起始min_x
    min_y = 24.263501#起始min_y
    max_x = 120.733278#結束max_x
    max_y = 24.237363#結束max_y


    #台南座標
    # min_x = 120.209867#起始min_x
    # min_y = 23.221069#起始min_y
    # max_x = 120.325223#結束max_x
    # max_y = 23.136486#結束max_y

    #台北座標
    # min_x = 121.521352#起始min_x
    # min_y = 25.061707#起始min_y
    # max_x = 121.571477#結束max_x
    # max_y = 25.023759#結束max_y

    # #金門座標
    # min_x = 118.383793
    # min_y = 24.480873
    # max_x = 118.444561
    # max_y = 24.433057


    #宜蘭
    # min_x = 121.761798
    # min_y = 24.686168
    # max_x = 121.784457
    # max_y = 24.665734

    #馬祖座標
    # min_x = 119.947280
    # min_y = 26.163167
    # max_x = 119.956464
    # max_y = 26.155155

#文件檔gpsrun.txt
#測試用座標，正式必須移除
#GPS修改 判斷是否空 - 引入最後一筆座標
	io_w = File.open("gpsrun.txt","a+")
	io_w.close
	io_r = File.open("gpsrun.txt","r+")
	if io_r.readlines.count !=0
		io_r.close
		io_r = File.open("gpsrun.txt","r+")
		init_latlng = io_r.readlines.last.to_s.chomp.split(",")
		init_x = init_latlng[1].to_f.round(7)
		init_y = init_latlng[0].to_f.round(7)
	    io_r.close
	    puts "GPS_開1,#{init_x},#{init_y}"
	else
	    io_r.close
        #台中測試座標
	    # min_x = 120.670853#測試用
		# min_y = 24.1531503#測試用

        #台南測試座標
        # min_x = 120.670853#測試用
        # min_y = 24.1531503#測試用

        #台北測試座標
        # min_x = 120.670853#測試用
        # min_y = 24.1531503#測試用


    	init_x = min_x #初始x if判斷是否有紀錄，為空則用min_x，此為運作座標x
    	init_y = min_y #初始y if判斷是否有紀錄，為空則用min_y，此為運作座標y
    	puts "GPS_開2,#{init_x},#{init_y}"
	end

	

    #迴圈次數   
    #總次數
    loop_total_x = 0#初始loop_total_x總次數-固定
    loop_total_y = 0#初始loop_total_y總次數-固定
    #取得loop_total_x、loop_total_y
    if (min_x<=>max_x)==-1&&(min_y<=>max_y) ==-1
    #min_x < max_x||min_y < max_y
    loop_total_x=(((max_x-min_x)/distance)*100).to_i/100.0
    loop_total_y=(((max_y-min_y)/distance)*100).to_i/100.0
    status_code=1
    puts "status_code=1"
    elsif (min_x<=>max_x)==1&&(min_y<=>max_y) ==-1
    #min_x > max_x||min_y < max_y
    loop_total_x=(((min_x-max_x)/distance)*100).to_i/100.0
    loop_total_y=(((max_y-min_y)/distance)*100).to_i/100.0
    status_code=2
    puts "status_code=2"
    elsif (min_x<=>max_x)==-1&&(min_y<=>max_y) ==1
    #min_x < max_x||min_y > max_y
    loop_total_x=(((max_x-min_x)/distance)*100).to_i/100.0
    loop_total_y=(((min_y-max_y)/distance)*100).to_i/100.0
    status_code=3
    puts "status_code=3"
    elsif (min_x<=>max_x)==1&&(min_y<=>max_y) ==1
    #min_x > max_x||min_y > max_y
    loop_total_x=(((min_x-max_x)/distance)*100).to_i/100.0
    loop_total_y=(((min_y-max_y)/distance)*100).to_i/100.0
    status_code=4
    puts "status_code=4"
    end#座標比對
    search_total = 1#截斷次數


	
    #已運行次數
    #用if判斷是否有最後一次的次數，如果空則是第一次
    #GPS修改 判斷是否空 - 引入最後一筆座標的次數修改

    io_r = File.open("gpsrun.txt","r+")
	if io_r.readlines.count !=0
		io_r.close
		io_r = File.open("gpsrun.txt","r+")
		init_loop_count = io_r.readlines.last.to_s.chomp.split(",")
		loop_count_x = init_latlng[3].to_i
		loop_count_y = init_latlng[2].to_i
		loop_op=0
	    io_r.close
	    puts "GPS_ok,#{init_x},#{init_y}"
	else
	    io_r.close
	    loop_count_x = 0#初始loop_count_x，此為loop已運行次數
    	loop_count_y = 0#初始loop_count_y，此為loop已運行次數
    	loop_op=0
    	puts "GPS_null,#{init_x},#{init_y}"
	end

case status_code
    when 1
        
    when 2

    when 3
        #狀態：min_x < max_x||min_y > max_y

        puts "次數："+"loop_op=>#{loop_op} , loop_count_x=>#{loop_count_x} , loop_count_y=>#{loop_count_y}, #{init_y},#{init_x}"
        #run y座標
        (init_y).step(max_y,-distance) do |run_y|
        #run_y(此刻的y)
        run_y.round(9)
        puts "RUN_Y___________________________________#{run_y}"
        loop_count_y+=1#計數y++

        #重置run_x，避免一開始以紀錄檔為基準
        if connect_count>1
            puts "重置run_x__________________________________________________________________________重置run_x"
            init_x = min_x    
        end


        (init_x).step(max_x,+distance) do |run_x|
        puts "迴圈開始座標____________________( #{run_y},#{run_x})"
        #run_x(此刻的x)
        run_x.round(9)
        puts "RUN_X___________________________________#{run_x}"

        loop_op = (loop_count_x/loop_count_y)+1

        complete = ((loop_op*loop_count_y)/(loop_total_x*loop_total_y))*100#完成度
        puts "座標完成度：#{complete}%"+"loop_op=>#{loop_op} , loop_count_x=>#{loop_count_x} , loop_count_y=>#{loop_count_y} , 連接數：#{connect_count}次"
        
        #GPS修改 儲存座標
        io_a = File.open("gpsrun.txt","a+")
        gpsrun_create = (run_y.round(7)).to_s+","+(run_x.round(7)).to_s+",#{loop_count_x},#{loop_count_y}\n"
        io_a.write(gpsrun_create)
        io_a.close

        #儲存為查詢用select_gps
        io_a = File.open("select_gps.txt","a+")      
        select_gps_create = "['"+(run_y.round(7)).to_s+","+(run_x.round(7)).to_s+"',"+(run_y.round(7)).to_s+","+(run_x.round(7)).to_s+",#{loop_count_x}],\n"
        io_a.write(select_gps_create)
        io_a.close


    	#JSON解析開始
    	#正式網址
    jsonurl_run = "https://maps.googleapis.com/maps/api/place/radarsearch/json?location=#{run_y},#{run_x}&key=#{$google_key}&radius=#{radius}&types=accounting | airport | amusement_park | aquarium | art_gallery | atm | bakery | bank | bar | beauty_salon | bicycle_store | book_store | bowling_alley | bus_station | cafe | campground | car_dealer | car_rental | car_repair | car_wash | casino | cemetery | church | city_hall | clothing_store | convenience_store | courthouse | dentist | department_store | doctor | electrician | electronics_store | embassy | establishment | finance | fire_station | florist | food | funeral_home | furniture_store | gas_station | general_contractor | grocery_or_supermarket | gym | hair_care | hardware_store | health | hindu_temple | home_goods_store | hospital | insurance_agency | jewelry_store | laundry | lawyer | library | liquor_store | local_government_office | locksmith | lodging | meal_delivery | meal_takeaway | mosque | movie_rental | movie_theater | moving_company | museum | night_club | painter | park | parking | pet_store | pharmacy | physiotherapist | place_of_worship | plumber | police | post_office | real_estate_agency | restaurant | roofing_contractor | rv_park | school | shoe_store | shopping_mall | spa | stadium | storage | store | subway_station | synagogue | taxi_stand | train_station | travel_agency | university | veterinary_care | zoo"
    
    #只有用""才能使用#{}，用''則無法
	puts "連接https_________location=#{run_y},#{run_x}"
    uri = URI(jsonurl_run)
    response = Net::HTTP.get(uri)
    connect_count+=1
    parsed = JSON.parse(response)
    p = parsed["results"].count
        if parsed["status"]=="OK"
        	puts "parsed OK"
        	@json_results_count = parsed["results"].count
        	result_run_count = @json_results_count#此為result解析剩餘的總數

        	(0..@json_results_count-1).each do |i|
        		@place_id = parsed["results"][i]["place_id"]
        		@lat=parsed["results"][i]["geometry"]["location"]["lat"]
        		@lng=parsed["results"][i]["geometry"]["location"]["lng"]
        		puts "parsed OK - #{@place_id}"
        		#while開關

        		#if下判斷不重複輸入place_id
        		ischeck_place_id = true
        		io_a = File.open("check_place.txt","a+")
				io_a.each_with_index{|place_line,index|
				    place_line.chomp!
				    if place_line==@place_id
				    # 比對到則重複為false
				    puts (place_line).to_s+",在第#{index+1}筆比對到"
				    ischeck_place_id = false
				    break
				    end
				}
				io_a.close
				
                @count_run_re+=1

				if !ischeck_place_id
                    puts "count_run_re+1＿＿＿＿＿＿＿＿＿＿總共#{@count_run_re}次"
        			# @count_run_re+=1

        		else
        			@count_run = @count_run_re+@count_run_no_re
                    puts "count_run_re＿＿＿＿＿＿＿＿＿＿總共#{@count_run_re}次"
        			if connect_count>=connect_total#連接數超過或等於connect_count，直接跳出json迴圈

        				if @count_run<result_run_count#解析數量小於result_run_count，不留記錄經緯度
        					puts "不留經緯度＿＿＿＿＿＿＿＿＿＿#{@count_run} < #{result_run_count}"
        					#GPS修改 判斷是否空 - 刪除最後一筆
        					io_r = File.open("gpsrun.txt","r+")
							io_a = File.open("gpsrun.txt","a+")
							if io_r.readlines.count !=0
							    io_r.close
							      io_a.truncate(io_a.size-io_a.readlines.last.size)
							      io_a.close

							      io_r = File.open("gpsrun.txt","r+")
							      p=io_r.readlines.count
							      io_r.close
							else
							      io_a.close
							      io_r.close
							end


        					#不增加，為原點
		 	       			puts "run_j____connect_count連線數："+(connect_count).to_s+"次"
	        				puts "目前座標____j____->(#{run_y},#{run_x})"
	        				puts "離開json迴圈"
	        				break
        				else#解析數量大於result_run_count，可以換下個經緯度，所以紀錄留著
        					#增加，下次已新點為起始
        					# GpsRun.create(:init_x => run_x, :init_y => run_y, :loop_count_x => loop_count_x, :loop_count_y => loop_count_y)
	        				puts "run_j____connect_count連線數："+(connect_count).to_s+"次"
	        				puts "目前座標____j____->(#{run_y},#{run_x})"
	        				puts "離開json迴圈"
	        				break
        				end
        				
        			else


        				take_shop_data_for_test_mysql(@place_id,@lat,@lng)
        				
        				if $isBreak==false
        					puts "$isBreak_____超過配置額＿＿＿＿＿＿#{$isBreak}"
        					over_query_limit_now +=1

        					#GPS修改 判斷是否空 - 刪除最後一筆
        					io_r = File.open("gpsrun.txt","r+")
							io_a = File.open("gpsrun.txt","a+")
							if io_r.readlines.count !=0
							    io_r.close
							      io_a.truncate(io_a.size-io_a.readlines.last.size)
							      io_a.close

							      io_r = File.open("gpsrun.txt","r+")
							      p=io_r.readlines.count
							      io_r.close
							else
							    io_a.close
							      io_r.close
							end

        					break
        				end
        				@count_run_no_re+=1
        				connect_count+=1
        				puts "獲取->店家ID："+@place_id+",店家座標："+"(#{@lat},#{@lng})"+"____共有：#{result_run_count}筆資料_______json迴圈共跑了，place_id已經跑了："+@count_run_re.to_s+"次 , place_id不重複："+@count_run_no_re.to_s+"次"
        			end
        		
        		end#判斷不重複輸入place_id
        		
        	end#json迴圈
	elsif parsed["status"]=="OVER_QUERY_LIMIT"
		puts "超出配額"
		over_query_limit_now +=1
		break
	else
		puts "NO"
		# render :text => "NO"
    end#判斷JSON的status

	loop_count_x+=1#計數x++

	if over_query_limit_now>=1#超出API查詢額度，直接跳出x迴圈
		break
	else
		if connect_count>=connect_total#連接數超過connect_count，停止
			# GpsRun.create(:init_x => run_x, :init_y => run_y, :loop_count_x => loop_count_x, :loop_count_y => loop_count_y)
			puts "run_x____connect_count連線數："+(connect_count).to_s+"次"
			puts "目前座標____x____->(#{run_y},#{run_x})"
			puts "離開1迴圈完畢"
			break
		end#連接數超過connect_count
		
	end
	



end#(init_x).step

	
	if over_query_limit_now>=1#超出API查詢額度，直接跳出y迴圈
		puts "____connect_count連線數："+(connect_count).to_s+"次"
		# render :text => "超過API查詢額度"
		break
	else
		if connect_count>=connect_total#連接數超過connect_count，停止
			puts "run_y____connect_count連線數："+(connect_count).to_s+"次"
			#不用座標，沒有x座標，只有y座標
			puts "離開y迴圈完畢"
			break
		end#連接數超過connect_count
	end


end#(init_y).step
    when 4
        

    else
        puts "break"
        
    end


puts "已完成雷達搜尋"


#JSON
#建構組織


  end

  def read

  end

def take_shop_data_for_test_mysql(place_id,lat,lng)
	@take_shop_data_place_id = place_id
	@take_shop_data_lat = lat
	@take_shop_data_lng = lng
	jsonurl_run = "https://maps.googleapis.com/maps/api/place/details/json?key=#{$google_key}&placeid=#{@take_shop_data_place_id}&language=zh-tw"
	
    uri = URI(jsonurl_run)
    response = Net::HTTP.get(uri)
    parsed = JSON.parse(response)
    place_id.to_s


	shop_name = ""
	shop_address = ""
    shop_zip_code = ""
	shop_phone_number = ""
	shop_map_url = ""
	shop_website = ""
	shop_img = ""
	shop_time_mon = ""
	shop_time_tue = ""
	shop_time_wed = ""
	shop_time_thu = ""
	shop_time_fri = ""
	shop_time_sat = ""
	shop_time_sun = ""
	shop_type = ""

	#若JSON狀態 == OK
    if parsed["status"]=="OK"
    	#name不為空，則爬取Json的name，並"更新"Shop資料表的shop_name
    	if !parsed["result"]["name"].nil?
    		shop_name = parsed["result"]["name"]
    	end
    	#formatted_address不為空，則爬取Json的name，並"更新"Shop資料表的address
		if !parsed["result"]["formatted_address"].nil?
			shop_address = parsed["result"]["formatted_address"]
		end
    
    	#formatted_phone_number不為空，則爬取Json的name，並"更新"Shop資料表的phone_number
		if !parsed["result"]["formatted_phone_number"].nil?
			shop_phone_number = parsed["result"]["formatted_phone_number"]
		end

		#url不為空，則爬取Json的name，並"更新"Shop資料表的google_map_url
		if !parsed["result"]["url"].nil?
			shop_map_url = parsed["result"]["url"]
		end

		#website不為空，則爬取Json的name，並"更新"Shop資料表的website
		if !parsed["result"]["website"].nil?
			shop_website = parsed["result"]["website"]
		end

		#photos不為空，則爬取Json的name，並"更新"Shop資料表的shop_photo_reference
		if !parsed["result"]["photos"].nil?
			shop_img = parsed["result"]["photos"][0]["photo_reference"]
		end

		#opening_hours不為空，判斷7天是否空並"增加"ShopTime資料表->time_*
		if !parsed["result"]["opening_hours"].nil?
			if !parsed["result"]["opening_hours"]["weekday_text"][0].nil?
				shop_time_mon = parsed["result"]["opening_hours"]["weekday_text"][0]
			end
			if !parsed["result"]["opening_hours"]["weekday_text"][1].nil?
				shop_time_tue = parsed["result"]["opening_hours"]["weekday_text"][1]
			end
			if !parsed["result"]["opening_hours"]["weekday_text"][2].nil?
				shop_time_wed = parsed["result"]["opening_hours"]["weekday_text"][2]
			end
			if !parsed["result"]["opening_hours"]["weekday_text"][3].nil?
				shop_time_thu = parsed["result"]["opening_hours"]["weekday_text"][3]
			end
			if !parsed["result"]["opening_hours"]["weekday_text"][4].nil?
				shop_time_fri = parsed["result"]["opening_hours"]["weekday_text"][4]
			end
			if !parsed["result"]["opening_hours"]["weekday_text"][5].nil?
				shop_time_sat = parsed["result"]["opening_hours"]["weekday_text"][5]
			end
			if !parsed["result"]["opening_hours"]["weekday_text"][6].nil?
				shop_time_sun = parsed["result"]["opening_hours"]["weekday_text"][6]
			end
		end

		#types不為空，型態有幾種，each找出型態並"增加"ShopType資料表->shop_type
		if !parsed["result"]["types"].nil?
			@type_count = parsed["result"]["types"].count
		    (0..@type_count-1).each do |i|
		    	if i==@type_count-1
                    shop_type += parsed["result"]["types"][i]
                elsif i==0
                    shop_type = parsed["result"]["types"][i]+","
                else
                    shop_type += parsed["result"]["types"][i]+","
                end
		    end
		end


      io_a = File.open("check_place.txt","a+")
      place_id_in_txt = "#{@take_shop_data_place_id}\n"
      io_a.write(place_id_in_txt)
      io_a.close


        if !parsed["result"]["address_components"].nil?
            shop_zip_code = parsed["result"]["address_components"].last["long_name"][0..2]
        end





#分流
take_zip_code=shop_zip_code[0..2]
ischeck=false
forplace = ""
case take_zip_code[0].to_i#take_zip_code第一碼
when 1
zip_code=["100","103","104","105","106","108","110","111","112","114","115","116"]
forplace_array = ["TAIPEI"]
# 台北市TAIPEI

(0..zip_code.count).each do |b|
	if take_zip_code.eql?zip_code[b]
	 forplace = forplace_array[0]
     place_zip_code = take_zip_code
	 puts "yes,第#{take_zip_code[0]}類,第#{b+1}個"+"在#{forplace}"
    
    begin
        
        Shop.create(:shop_name => shop_name, :shop_lat => @take_shop_data_lat, :shop_lng => @take_shop_data_lng, :place_id => @take_shop_data_place_id, :address => shop_address, :phone_number => shop_phone_number, :google_map_url => shop_map_url, :website  => shop_website)
        ShopPlaceCounty.create(:place_id => @take_shop_data_place_id, :place_county  => forplace, :place_zip_code => place_zip_code)
        ShopImg.create(:place_id => @take_shop_data_place_id, :shop_photo_reference  => shop_img)
        ShopTime.create(:place_id => @take_shop_data_place_id, :time_mon => shop_time_mon, :time_tue => shop_time_tue, :time_wed => shop_time_wed, :time_thu => shop_time_thu, :time_fri => shop_time_fri, :time_sat => shop_time_sat, :time_sun  => shop_time_sun)
        ShopType.create(:place_id => @take_shop_data_place_id, :shop_type  => shop_type)

    rescue Exception => e
        puts e
    end
	 break#已經找到，離開
	else
	 puts "no"
	end#比對zip_code判斷

end#離開迴圈b


when 2

zip_code=["200","201","202","203","204","205","206"],["207","208","220","221","222","223","224","226","227","228","231","232","233","234","235","236","237","238","239","241","242","243","244","247","248","249","251","252","253"],["260","261","262","263","264","265","266","267","268","269","270","272"],["209","210","211","212"]
forplace_array = ["KEELUNG","NEWTAIPEI","YILAN","LIENCHIANG"]
# 基隆市KEELUNG,新北市NEWTAIPEI,宜蘭縣YILAN,馬祖LIENCHIANG

(0..zip_code.count-1).each do |a|
	(0..zip_code[a].count-1).each do |b|
	if take_zip_code.eql?zip_code[a][b]
		forplace = forplace_array[a]
        place_zip_code = take_zip_code
		puts "yes,第#{take_zip_code[0]}類,第#{a+1}陣列第#{b+1}個"+"在#{forplace}"
		
    begin
        
        Shop.create(:shop_name => shop_name, :shop_lat => @take_shop_data_lat, :shop_lng => @take_shop_data_lng, :place_id => @take_shop_data_place_id, :address => shop_address, :phone_number => shop_phone_number, :google_map_url => shop_map_url, :website  => shop_website)
        ShopPlaceCounty.create(:place_id => @take_shop_data_place_id, :place_county  => forplace, :place_zip_code => place_zip_code)
        ShopImg.create(:place_id => @take_shop_data_place_id, :shop_photo_reference  => shop_img)
        ShopTime.create(:place_id => @take_shop_data_place_id, :time_mon => shop_time_mon, :time_tue => shop_time_tue, :time_wed => shop_time_wed, :time_thu => shop_time_thu, :time_fri => shop_time_fri, :time_sat => shop_time_sat, :time_sun  => shop_time_sun)
        ShopType.create(:place_id => @take_shop_data_place_id, :shop_type  => shop_type)

    rescue Exception => e
        puts e
    end
        
		ischeck=true
		break
	else
	 puts "no"
	end
end#離開迴圈b
if ischeck#已經找到，離開
	break	
end#正在迴圈a
end#離開迴圈a

when 3
	zip_code = ["300"],["302","303","304","305","306","307","308","310","311","312","313","314","315"],["320","324","325","326","327","328","330","333","334","335","336","337","338"],["350","351","352","353","354","356","357","358","360","361","362","363","364","365","366","367","368","369"]
	forplace_array = ["HSINCHUCITY","HSINCHU","TAOYUAN","MIAOLI"]
	# 新竹市HSINCHUCITY,新竹縣HSINCHU,桃園市TAOYUAN,苗栗縣MIAOLI

	(0..zip_code.count-1).each do |a|
	(0..zip_code[a].count-1).each do |b|
	if take_zip_code.eql?zip_code[a][b]
		forplace = forplace_array[a]
        place_zip_code = take_zip_code
		puts "yes,第#{take_zip_code[0]}類,第#{a+1}陣列第#{b+1}個"+"在#{forplace}"
		
    begin
        
        Shop.create(:shop_name => shop_name, :shop_lat => @take_shop_data_lat, :shop_lng => @take_shop_data_lng, :place_id => @take_shop_data_place_id, :address => shop_address, :phone_number => shop_phone_number, :google_map_url => shop_map_url, :website  => shop_website)
        ShopPlaceCounty.create(:place_id => @take_shop_data_place_id, :place_county  => forplace, :place_zip_code => place_zip_code)
        ShopImg.create(:place_id => @take_shop_data_place_id, :shop_photo_reference  => shop_img)
        ShopTime.create(:place_id => @take_shop_data_place_id, :time_mon => shop_time_mon, :time_tue => shop_time_tue, :time_wed => shop_time_wed, :time_thu => shop_time_thu, :time_fri => shop_time_fri, :time_sat => shop_time_sat, :time_sun  => shop_time_sun)
        ShopType.create(:place_id => @take_shop_data_place_id, :shop_type  => shop_type)

    rescue Exception => e
        puts e
    end
		ischeck=true
		break
	else
	 puts "no"
	end
end#離開迴圈b
if ischeck#已經找到，離開
	break	
end#正在迴圈a
end#離開迴圈a

when 4
	zip_code = ["400","401","402","403","404","406","407","408","411","412","413","414","420","421","422","423","424","426","427","428","429","432","433","434","435","436","437","438","439"]
	forplace_array = ["TAICHUNG"]
	# 台中市TAICHUNG

	(0..zip_code.count).each do |b|
	if take_zip_code.eql?zip_code[b]
	 forplace = forplace_array[0]
     place_zip_code = take_zip_code
	 puts "yes,第#{take_zip_code[0]}類,第#{b+1}個"+"在#{forplace}"
		
    begin
        
        Shop.create(:shop_name => shop_name, :shop_lat => @take_shop_data_lat, :shop_lng => @take_shop_data_lng, :place_id => @take_shop_data_place_id, :address => shop_address, :phone_number => shop_phone_number, :google_map_url => shop_map_url, :website  => shop_website)
        ShopPlaceCounty.create(:place_id => @take_shop_data_place_id, :place_county  => forplace, :place_zip_code => place_zip_code)
        ShopImg.create(:place_id => @take_shop_data_place_id, :shop_photo_reference  => shop_img)
        ShopTime.create(:place_id => @take_shop_data_place_id, :time_mon => shop_time_mon, :time_tue => shop_time_tue, :time_wed => shop_time_wed, :time_thu => shop_time_thu, :time_fri => shop_time_fri, :time_sat => shop_time_sat, :time_sun  => shop_time_sun)
        ShopType.create(:place_id => @take_shop_data_place_id, :shop_type  => shop_type)

    rescue Exception => e
        puts e
    end
	 break#已經找到，離開
	else
	 puts "no"
	end#比對zip_code判斷

end#離開迴圈b

when 5
	zip_code = ["500","502","503","504","505","506","507","508","509","510","511","512","513","514","515","516","520","521","522","523","524","525","526","527","528","530"],["540","541","542","544","545","546","551","552","553","555","556","557","558"]
	forplace_array = ["CHANGHUA","NANTOU"]
	# 彰化縣CHANGHUA,南投市NANTOU

	(0..zip_code.count-1).each do |a|
	(0..zip_code[a].count-1).each do |b|
	if take_zip_code.eql?zip_code[a][b]
		forplace = forplace_array[a]
        place_zip_code = take_zip_code
		puts "yes,第#{take_zip_code[0]}類,第#{a+1}陣列第#{b+1}個"+"在#{forplace}"
		
    begin
        
        Shop.create(:shop_name => shop_name, :shop_lat => @take_shop_data_lat, :shop_lng => @take_shop_data_lng, :place_id => @take_shop_data_place_id, :address => shop_address, :phone_number => shop_phone_number, :google_map_url => shop_map_url, :website  => shop_website)
        ShopPlaceCounty.create(:place_id => @take_shop_data_place_id, :place_county  => forplace, :place_zip_code => place_zip_code)
        ShopImg.create(:place_id => @take_shop_data_place_id, :shop_photo_reference  => shop_img)
        ShopTime.create(:place_id => @take_shop_data_place_id, :time_mon => shop_time_mon, :time_tue => shop_time_tue, :time_wed => shop_time_wed, :time_thu => shop_time_thu, :time_fri => shop_time_fri, :time_sat => shop_time_sat, :time_sun  => shop_time_sun)
        ShopType.create(:place_id => @take_shop_data_place_id, :shop_type  => shop_type)

    rescue Exception => e
        puts e
    end
		ischeck=true
		break
	else
	 puts "no"
	end
end#離開迴圈b
if ischeck#已經找到，離開
	break	
end#正在迴圈a
end#離開迴圈a



when 6
	zip_code = ["600"],["602","603","604","605","606","607","608","611","612","613","614","615","616","621","622","623","624","625"],["630","631","632","633","634","635","636","637","638","640","643","646","647","648","649","651","652","653","654","655"]
	forplace_array = ["CHIAYICITY","CHIAYI","YUNLIN"]
	# 嘉義市CHIAYICITY,嘉義縣CHIAYI,雲林縣YUNLIN

	(0..zip_code.count-1).each do |a|
	(0..zip_code[a].count-1).each do |b|
	if take_zip_code.eql?zip_code[a][b]
		forplace = forplace_array[a]
        place_zip_code = take_zip_code
		puts "yes,第#{take_zip_code[0]}類,第#{a+1}陣列第#{b+1}個"+"在#{forplace}"
		
    begin
        
        Shop.create(:shop_name => shop_name, :shop_lat => @take_shop_data_lat, :shop_lng => @take_shop_data_lng, :place_id => @take_shop_data_place_id, :address => shop_address, :phone_number => shop_phone_number, :google_map_url => shop_map_url, :website  => shop_website)
        ShopPlaceCounty.create(:place_id => @take_shop_data_place_id, :place_county  => forplace, :place_zip_code => place_zip_code)
        ShopImg.create(:place_id => @take_shop_data_place_id, :shop_photo_reference  => shop_img)
        ShopTime.create(:place_id => @take_shop_data_place_id, :time_mon => shop_time_mon, :time_tue => shop_time_tue, :time_wed => shop_time_wed, :time_thu => shop_time_thu, :time_fri => shop_time_fri, :time_sat => shop_time_sat, :time_sun  => shop_time_sun)
        ShopType.create(:place_id => @take_shop_data_place_id, :shop_type  => shop_type)

    rescue Exception => e
        puts e
    end
		ischeck=true
		break
	else
	 puts "no"
	end
end#離開迴圈b
if ischeck#已經找到，離開
	break	
end#正在迴圈a
end#離開迴圈a

when 7
	zip_code = ["700","701","702","704","708","709","710","711","712","713","714","715","716","717","718","719","720","721","722","723","724","725","726","727","730","731","732","733","734","735","736","737","741","742","743","744","745"]
	forplace_array = ["TAINAN"]
	# 台南市TAINAN

	(0..zip_code.count).each do |b|
	if take_zip_code.eql?zip_code[b]
	 forplace = forplace_array[0]
     place_zip_code = take_zip_code
	 puts "yes,第#{take_zip_code[0]}類,第#{b+1}個"+"在#{forplace}"
		
    begin
        
        Shop.create(:shop_name => shop_name, :shop_lat => @take_shop_data_lat, :shop_lng => @take_shop_data_lng, :place_id => @take_shop_data_place_id, :address => shop_address, :phone_number => shop_phone_number, :google_map_url => shop_map_url, :website  => shop_website)
        ShopPlaceCounty.create(:place_id => @take_shop_data_place_id, :place_county  => forplace, :place_zip_code => place_zip_code)
        ShopImg.create(:place_id => @take_shop_data_place_id, :shop_photo_reference  => shop_img)
        ShopTime.create(:place_id => @take_shop_data_place_id, :time_mon => shop_time_mon, :time_tue => shop_time_tue, :time_wed => shop_time_wed, :time_thu => shop_time_thu, :time_fri => shop_time_fri, :time_sat => shop_time_sat, :time_sun  => shop_time_sun)
        ShopType.create(:place_id => @take_shop_data_place_id, :shop_type  => shop_type)

    rescue Exception => e
        puts e
    end
	 break#已經找到，離開
	else
	 puts "no"
	end#比對zip_code判斷

end#離開迴圈b


when 8
	zip_code = ["800","801","802","803","804","805","806","807","811","812","813","814","815","820","821","822","823","824","825","826","827","828","829","830","831","832","833","840","842","843","844","845","846","847","848","849","851","852"],["880","881","882","883","884","885"],["890","891","892","893","894","896"]
	forplace_array = ["KAOHSIUNG","PENGHU","KINMEN"]
	# 高雄市KAOHSIUNG,澎湖縣PENGHU,金門縣KINMEN

	(0..zip_code.count-1).each do |a|
	(0..zip_code[a].count-1).each do |b|
	if take_zip_code.eql?zip_code[a][b]
		forplace = forplace_array[a]
        place_zip_code = take_zip_code
		puts "yes,第#{take_zip_code[0]}類,第#{a+1}陣列第#{b+1}個"+"在#{forplace}"
		
    begin
        
        Shop.create(:shop_name => shop_name, :shop_lat => @take_shop_data_lat, :shop_lng => @take_shop_data_lng, :place_id => @take_shop_data_place_id, :address => shop_address, :phone_number => shop_phone_number, :google_map_url => shop_map_url, :website  => shop_website)
        ShopPlaceCounty.create(:place_id => @take_shop_data_place_id, :place_county  => forplace, :place_zip_code => place_zip_code)
        ShopImg.create(:place_id => @take_shop_data_place_id, :shop_photo_reference  => shop_img)
        ShopTime.create(:place_id => @take_shop_data_place_id, :time_mon => shop_time_mon, :time_tue => shop_time_tue, :time_wed => shop_time_wed, :time_thu => shop_time_thu, :time_fri => shop_time_fri, :time_sat => shop_time_sat, :time_sun  => shop_time_sun)
        ShopType.create(:place_id => @take_shop_data_place_id, :shop_type  => shop_type)

    rescue Exception => e
        puts e
    end
		ischeck=true
		break
	else
	 puts "no"
	end
end#離開迴圈b
if ischeck#已經找到，離開
	break	
end#正在迴圈a
end#離開迴圈a

when 9
	zip_code = ["900","901","902","903","904","905","906","907","908","909","911","912","913","920","921","922","923","924","925","926","927","928","929","931","932","940","941","942","943","944","945","946","947"],["950","951","952","953","954","955","956","957","958","959","961","962","963","964","965","966"],["970","971","972","973","974","975","976","977","978","979","981","982","983"]
	forplace_array = ["PINGTUNG","TAITUNG","HUALIEN"]
	# 屏東縣PINGTUNG,台東縣TAITUNG,花蓮縣HUALIEN

	(0..zip_code.count-1).each do |a|
	(0..zip_code[a].count-1).each do |b|
	if take_zip_code.eql?zip_code[a][b]
		forplace = forplace_array[a]
        place_zip_code = take_zip_code
		puts "yes,第#{take_zip_code[0]}類,第#{a+1}陣列第#{b+1}個"+"在#{forplace}"
		
    begin
        
        Shop.create(:shop_name => shop_name, :shop_lat => @take_shop_data_lat, :shop_lng => @take_shop_data_lng, :place_id => @take_shop_data_place_id, :address => shop_address, :phone_number => shop_phone_number, :google_map_url => shop_map_url, :website  => shop_website)
        ShopPlaceCounty.create(:place_id => @take_shop_data_place_id, :place_county  => forplace, :place_zip_code => place_zip_code)
        ShopImg.create(:place_id => @take_shop_data_place_id, :shop_photo_reference  => shop_img)
        ShopTime.create(:place_id => @take_shop_data_place_id, :time_mon => shop_time_mon, :time_tue => shop_time_tue, :time_wed => shop_time_wed, :time_thu => shop_time_thu, :time_fri => shop_time_fri, :time_sat => shop_time_sat, :time_sun  => shop_time_sun)
        ShopType.create(:place_id => @take_shop_data_place_id, :shop_type  => shop_type)

    rescue Exception => e
        puts e
    end
		ischeck=true
		break
	else
	 puts "no"
	end
end#離開迴圈b
if ischeck#已經找到，離開
	break	
end#正在迴圈a
end#離開迴圈a


else
	puts "無匹配zip_code"
	
end
		    	puts "take_shop_data => OK"
    
    elsif parsed["status"]=="OVER_QUERY_LIMIT"
		puts "超出配額______take____data__________配額超出"
		$isBreak=false
		return $isBreak
		# returnbreak
    else
    	puts "take_shop_data => status:NO"
    end
    
	
end
def round_to(x)
    (self * 10**x).round.to_f / 10**x
end

end

