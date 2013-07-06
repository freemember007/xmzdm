# encoding: utf-8

# task :grab do
  require 'rubygems'
  require 'thread'
  require 'active_record'
  require 'searchlogic'
  require 'weibo2'
  require 'nokogiri'
  require 'open-uri'
  require 'json'
  require './deal_site.rb'
  require './deal.rb'

  ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database => "dealdev.sqlite",
    :pool => 5,
    :timeout => 5000
  )
  
  # oauth2.0 基 础 配 置
  Weibo2::Config.api_key = "2879718887"
  Weibo2::Config.api_secret = "687dcb176438571f9c0cabc61b914ad2"
  Weibo2::Config.redirect_uri = "http://xmzdm.com"
  
  # 得 到 acesstoken, 仅 需 运 一 次 ! 第 三 行 是 获 取 到 的 地 址
  #client = Weibo2::Client.new
  #puts client.auth_code.authorize_url(:response_type => "token")
 #https://api.weibo.com/oauth2/authorize?client_id=2879718887&response_type=token&redirect_uri=http://184.82.79.30/callback
 
  # 用 获 取 到 的 accesstoken 组 装 请 求 方 法 , accesstoken需使用上面的地址每天换一次
  client = Weibo2::Client.from_hash(:access_token => "2.00xudY2Bp7AtIDfb89a2306f0o2KP2", :expires_in => 86400)
  
  # 遍 历 要 抓 取 的 帐 号 ， 获 取 其 微 博 内 容
  @dealsite = DealSite.find(:all,
  :conditions => "disable = 'false'"
  )
  for dealsite in @dealsite
    puts "\n\n开始获取微博内容 ====#{dealsite.id}.#{dealsite.name}(#{dealsite.uid})===="
    attempts = 0
    begin
      response = client.statuses.user_timeline(opts={
        :uid => dealsite.uid, 
        :count => 10,
        :feature => 1,
        :trim_user => 1
        })
    rescue Exception => ex
      puts ex.message
      attempts = attempts + 1
      sleep(3)
      puts ">>第#{attempts}次重试(获取微博内容)..."
      retry if(attempts < 5)
    end  
      
    # 遍 历 statuses hash
    response.parsed["statuses"].reverse.each do |hash|
      title = hash["text"]
      description = hash["text"]
      image_url = hash["thumbnail_pic"]
      mimage_url = hash["bmiddle_pic"]
      puts mimage_url

      deal = Deal.find(:all, 
      :conditions => ["deals.title = ?", title]
      )     
      
      if deal[0] == nil and image_url != nil
      puts ">>>是的，数据库中不存在此条数据且内容中带图片:"
      puts " 来自《#{dealsite.name}》"
      puts title
      puts "等待3秒，判断title是否符合规则..."
      sleep(3)
        # 判断title是否符合规则
        if title =~ /\d元|\d美刀|\d刀|\d美元|价格\d|购价\d|价为\d|\d折|满\d+减n\d+|\d折|活动时间|立减\d|限时抢|手慢无|\d包邮|￥\d|\$\d/ and title =~ /(http:\/\/t\.cn\/[a-z0-9A-Z]*)/
          link = title.match(/http:\/\/t\.cn\/[a-z0-9A-Z]*/).to_s
          puts link
          alink = link #以防万一后面没去给alink赋值，是否需要？貌似必要
          attempts = 0
          begin
            alink = open(link).base_uri.to_s
          rescue Exception => ex
            puts ex.message
            attempts = attempts + 1
            puts ">>第#{attempts}次重试（获取来源地址）..."
            retry if(attempts < 5)
          end
          puts alink
          blink = alink #以防万一后面没去给blink赋值，是否需要？貌似必要
          
          # 取 基 本 信 息
          @deal = Deal.new
          @deal.title = title
          @deal.deal_site_id = dealsite.id
          @deal.time = Time.gm(*Time.now)
          @deal.image_url = image_url
          @deal.mimage_url = mimage_url
          @deal.alink = alink
          @deal.blink = blink # 是否必要？貌似必要
          @deal.description = description
        
          # 取 品 牌
          file = File.open("branddict.txt","r")
          file.each_line do |line|
            if title.include? line.chop
              @deal.brand = line.chop
              puts ">>得到品牌：#{line}"
              break
            end
          end
        
          # 取 商 品 名
          response = nil
          open("pnamedict.json","r") do |file|
            response = file.read
          end
          json = JSON::parse(response)
          json.each do |k,v|
            v.each do |pname|
              if title.include? pname
                @deal.pname = pname
                @deal.catlog = k.to_i
                break
              end
            end
          end
        
          # 取 价 格 与 币 种
          if title =~ /(\d+\.?\d*)美[刀元]|(\d+\.?\d*)刀|\$(\d+\.?\d*)/
            @deal.price = "$" + [$1,$2,$3].compact[0]
            @deal.country = 2
          elsif title =~ /(\d+\.?\d*)元|￥(\d+\.?\d*)|价格(\d+\.?\d*)/
            @deal.price = "¥" + [$1,$2,$3].compact[0]
            @deal.country = 1
          end
        
          ## 取 商 品 型 号
          str = title.gsub(/(，|。|！|!|：|:|-)\s*[a-zA-z]+\:\/\/[^\s]*|[a-zA-z]+\:\/\/[^\s]*|\d+ml|\d+ML|\d+[gG]|\d+GB|\d+MB|B2C|b2c|\d+cm|\d+CM/, '')
          str.scan(/[\w\d-]{3,20}/).each do |a|
            if (a =~ /\d/ and a =~ /[a-zA-Z]/) or (a =~ /^.+-.+$/ and a !~ /\d+0-\d+0/)
              @deal.model = a
              break
              #puts ">>得到商品型号：#{a}"
            end
          end
          
          puts ">>判断是否为抄袭...(这个地方有问题，若品牌同，商品名不同，无法判断重复，需要两个变量，但两个变量语法错误，什么原因？跟if语句有关?还是跟&&有关?)"
          if @deal.brand != nil
            #t = (Time.now-50400).strftime("%Y-%m-%d %H:%M:%S")
            deal = Deal.price_is(@deal.price).brand_is(@deal.brand).time_after(Time.now - 1.days).all
            
          end
            
          if @deal.pname != nil
            deal = Deal.price_is(@deal.price).pname_is(@deal.pname).time_after(Time.now - 2.days).all
          end
          
          if deal[0] == nil or ( @deal.brand == nil && @deal.pname == nil )
          
          # 取 购 买 链 接 与 描 述
          puts "-----条件均符合且为原创，开始解析url #{alink}..."
          doc = nil
          attempts = 0
          begin
            doc = Nokogiri::HTML(open(alink).read.strip)
          rescue Exception => ex
            puts ex.message
            attempts = attempts + 1
            puts "OMG，没成功，先休息2秒再重试..."
            sleep(2)
            puts ">>第#{attempts}次重试（解析商品网址）..."
            retry if(attempts < 3)
          end
        
          if doc != nil
            doc.css("#single a, #topic a, #article a, #main a, .main a,  #content a, .content a, #context a, .context a, #post a, #postlist a, .post a, #article_content a, .article_content a, #ct a, .discount-detail a").each do |a|
              reg = /更多详情|购买链接|直 达 链 接|直达链接|点击购买|点此购买|无返利点此|购买点此|查看详情点此|链接在此|去购物，拿返现|地址在这里|点击这里|点我查看|链接|立即购买|无返利点击|购买页面|去商品购买页面|去商城选购|链接|go_buy|link|goto|\/go\/|redirect|linkCode=|yiqifa|color="Red"|click\.taobao|\/product\/|\/Product\/|union\.360buy|to=/
              if a.text =~ reg or a[:title] =~ reg or a[:href] =~ reg
                # 获取原始购买地址，相对网址补全
                if a[:href] =~ /[a-zA-z]+:\/\/[^\s]*/
                  blink = a[:href]
                else
                  blink = "http://" + URI.parse(alink).host + "/" + a[:href]
                end
                puts ">>得到原始购买链接：#{blink}"
                
                # 获取跳转后的地址，注意：此处有一URI::InvalidURIError的问题待解决！！！
                attempts = 0
                begin
                  blink = open(URI.encode(blink)).base_uri.to_s
                rescue Exception => ex
                  puts ex.message
                  attempts = attempts + 1
                  puts ">>第#{attempts}次重试（获取真实购买地址）..."
                  break if(attempts < 5)
                end
                puts ">>得到真实购买链接为：#{blink}"
                
                # 从淘宝、京东、一起发等广告联盟地址获取真实地址并转码（正常URL不影响，神奇的代码！！！）
                @deal.blink = URI.decode(URI.decode(blink).gsub(/(http.*=)?(http.*)/,'\2'))
                break
              end
            end
            doc.css("#single p, #topic p, #article p, #main p, #content p, .content p, #context p, .context p, #post p, #postlist p, #postlist font, .post p, #article_content p, #article_content font, .article_content p, #ct p, .discount-detail p, .main p").each do |p|
              reg =/.{100,}/
              if p.text =~ reg && p.text !~ /html|HTML|Html/
                @deal.description = p.text
                puts ">>得到新描述：#{p.text}"
                break
              end
            end
          end
        
          # 把 数 据 狠 稳 地 存 入 数 据 库 ！
          @deal.save
          
          else
            puts ">>>该文系抄袭《#{deal[0].deal_site.name}》！#{deal[0].time}\n #{deal[0].title}  "
            sleep(3)
          end # 结 束 是 否 抄 袭 分 析
          
        end # 结 束 title 规 则 分 析
        
      else
        puts "oh,no,数据库中已存在此条数据或内容中不带图片！"
      end # 结 束 本 条 status 分 析
      
    end # 结 束 statuses 循 环 体
  end # 结 束 帐 号 循 环 体
# end # 结 束 task
