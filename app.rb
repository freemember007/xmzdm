# encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'active_record'
require 'searchlogic'
require './deal_site.rb'
require './deal.rb'
require 'rack/cache'
require 'sinatra/cache'

puts '连接数据库'
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "dealdev.sqlite",
  :pool => 50, #确实有效，但会增加内存消耗，还有无更好办法？
  :timeout => 5000 #这个貌似没用
)

reg = /来自@淘点便宜货网 --详情请点击：|（来源网站：http:\/\/t\.cn\/[a-z0-9A-Z]*） @淘必得|(，|。|！|!|：|:|-)\s*[a-zA-z]+\:\/\/[^\s]*|[a-zA-z]+\:\/\/[^\s]*|#.*?#|\[.*?\]|\|.*|- 真的值得买，什么值得买，每日推荐网购优惠信息，海淘、海外购优惠促销值值值尽在“真的值得买”|促销详情:|来自: @什么值得买|来自: @值值值 - 详情请看:|来自@美国便宜货网|来自:@趣购365|\[更多优惠信息，请访问我们的论坛|更多国外优惠信息|\| 活动页面点此.*|购买链接在此|\.\.\s+（来源网站|商品介绍点击链接在此|详情请见|，优惠信息内详|更多优惠信息|，请访问我们的网站|更多优惠|更多信息|链接在此 - 详情请看：|\| 详情点此了解|点击查看>>>>|（购买页面）|【.{1,30}】|点击选购>>>>|>>>|购买点此|无返利点此|，购买点击|团购链接|，链接在此，|直接地址|，团购地址|团购地址|抢购点击|\[链接在此\]|猛击链接|直达电商连接|详情页面:|详情：|- 详情请看：|详情请看|详情|传送门|相关视频|视频页面:|@什么可以买：|非败不可|\|\| 每天优惠多|\| 每天优惠多|》\|\| 值不值得买 ？|》值不值得买？|》值不值得买 |》值不值得买|【趣购推荐】|【更新:得利网】|【得利网】|（分享自 @harlemyin）|\| CheapHuo\|易活|，到手.+元|（.*到手.+）|(，|,|。|！|!|：|:)$|　+/

puts '系统配置'
configure do # 配置文件，服务启动时运行一次
  # 声明浏览器缓存
  use Rack::Cache # 设置是必须的，否则后面虽无语法错误，但cache无效
  # 声明服务端缓存
  set :cache_enabled, true
  set :cache_enabled_for, :all
  set :cache_page_extension, '.html'
  set :cache_output_dir, 'cache' # 设置是必须的，否则报方法私有错误
end

puts '加载帮助'
helpers do
  def post_time
    (@deal.time + 50400).strftime("%m月%d日 %H:%M")
  end
end

puts '加载路由与控制器'
get '/api/feed' do
  deal = Deal.find(:all,
  :limit => 30,
  :order => 'id DESC')
  deal.to_json
end

get '/' do
  @deal = Deal.find(:all, 
  :limit => 30,   
  :order => 'id DESC')
  @title = '今日最新'
  erb :index
end

get '/catlog/:catlog_id/:name' do
  @deal = Deal.find(:all, 
  :limit => 50, 
  :conditions => ["catlog = ?", "#{params[:catlog_id]}"],  
  :order => 'id DESC')
  @title =  params[:name]
  erb :catlog
end

get '/site/:name' do
  @deal = Deal.find(:all, 
  :limit => 50, 
  :conditions => ["blink like ?", "%#{params[:name]}%"],  
  :order => 'id DESC')
  @title =  params[:name]
  erb :site
end

get '/promotion' do
  @deal = Deal.title_like("促销活动").all :limit => 50, :order => 'id DESC'
  @title = '促销活动'
  erb :promotion

end

get '/search' do
  @deal = Deal.find(:all, 
  :limit => 50, 
  :conditions => ["title like ?", "%#{params[:q]}%"],
  :order => 'id DESC')
  erb :search
end

get '/detail/:id' do
  #cache_control :public, :max_age => 36000 # 浏览器缓存
  @deal = Deal.find(:all, 
  :conditions => ["id = ?", "#{params[:id]}"])
  @title = @deal[0].title.gsub(reg, '')
  erb :detail
end

get '/source/15' do
  @deal = Deal.find(:all, 
  :conditions => {:deal_site_id => 15},
  :limit => 50, 
  :order => 'id DESC')
  erb :coupon
  #cache( erb( :source ))
end

get '/coupons' do
  @deal = Deal.find(:all, 
  :conditions => {:deal_site_id => 15},
  :limit => 50, 
  :order => 'id DESC')
  @title = '优惠券'
  erb :coupons
  #cache( erb( :pname ))
end

get '/source/:site_id' do
  @deal = Deal.find(:all, 
  :conditions => {:deal_site_id => params[:site_id]},
  :limit => 50, 
  :order => 'id DESC')
  @dealsite = DealSite.find(:all,
  :conditions => ["id = ?", "#{params[:site_id]}"]
  )
  erb :source
  #cache( erb( :source ))
end

get '/brand/:name' do
  @deal = Deal.find(:all, 
  :conditions => ["brand like ?", "%#{params[:name]}%"],
  :limit => 50, 
  :order => 'id DESC')
  @title = params[:name]
  erb :brand
  #cache( erb( :brand ))
end

get '/pname/:name' do
  @deal = Deal.find(:all, 
  :conditions => ["pname like ?", "%#{params[:name]}%"],
  :limit => 50, 
  :order => 'id DESC')
  @title = params[:name]
  erb :pname
  #cache( erb( :pname ))
end

get '/model/:model' do
  @deal = Deal.find(:all, 
  :conditions => ["model like ?", "%#{params[:model]}%"],
  :limit => 50, 
  :order => 'id DESC')
  @title = params[:model]
  erb :model
  #cache( erb( :model ))
end

get '/page/:page' do
  @deal = Deal.find(:all, 
  :limit => 30,   
  :offset => (params[:page].to_i-1)*30||0,  
  :order => 'id DESC')
  erb :index
end

get '/china' do
  @deal = Deal.find(:all,
  :conditions => "country = 1",
  :limit => 30, 
  :order => 'id DESC')
  @title = '国内购'
  erb :china
end

get '/usa' do
  @deal = Deal.find(:all,
  :conditions => "country = 2",
  :limit => 30, 
  :order => 'id DESC')
  @title = '海外购'
  erb :usa
end

#貌似没啥用，先放着：
# ActiveRecord::Base.clear_active_connections!