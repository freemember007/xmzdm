require 'rubygems'
require 'nokogiri'
require 'open-uri'

# 测试抓取
puts "开始测试解析购买链接与描述..."
# 取 购 买 链 接 与 描 述
alink = "http://www.yhzzd.com/archives/18694"
blink = alink
puts "链接为#{alink}"
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
    reg = /更多详情|购买链接|直 达 链 接|直达链接|点击购买|点此购买|无返利点此|购买点此|查看详情点此|链接在此|去购物，拿返现|地址在这里|点击这里|点我查看|链接|立即购买|无返利点击|购买页面|去商品购买页面|去商城选购|链接|go_buy|link|goto|\/go\/|to=|redirect|linkCode=|yiqifa|color="Red"|click\.taobao/
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
        retry if(attempts < 3)
      end
      puts ">>得到真实购买链接为：#{blink}"
      
      # 从淘宝、京东、一起发等广告联盟地址获取真实地址并转码（正常URL不影响，神奇的代码！！！）
      blink = URI.decode(URI.decode(blink).gsub(/(http.*=)?(http(%3A|:).*)/,'\2'))
      puts ">>得到截取后的真实购买链接为：#{blink}"
      
      blink =  URI.decode(blink)
      puts ">>得到再次转码后的真实购买链接为：#{blink}"
      break
    end
  end
  doc.css("#single p, #topic p, #article p, #main p, #content p, .content p, #context p, .context p, #post p, #postlist p, #postlist font, .post p, #article_content p, #article_content font, .article_content p, #ct p, .discount-detail p, .main p").each do |p|
    reg =/.{100,}/
    if p.text =~ reg && p.text !~ /html|HTML|Html/
      puts ">>得到新描述：#{p.text}"
      break
    end
  end
end


#client = Weibo2::Client.from_hash(:access_token => "2.00xudY2BtrrDcD97c7faf42fScc1mB", :expires_in => 86400)

#sid = client.statuses.queryid("ye8cgg7rv", type=1, opts={
#  :isBase62  => 1
#})

#puts id = sid.parsed
#status = client.statuses.show(id["id"])

#puts status.parsed
