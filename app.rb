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
  :pool => 20, #确实有效，但会增加内存消耗，还有无更好办法？
  :timeout => 2000 #这个貌似没用
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
  use Rack::Deflater # 使用gzip
end

puts '加载帮助'
helpers do
  def post_time
    (@deal.time + 20400).strftime("%m月%d日 %H:%M")
  end
end


################## 网站路由 ######################

get '/' do
  @deal = Deal.find(:all, 
  :limit => 20, 
  :order => 'id DESC')
  @title = '今日最新'
  @next = '/page/2'
  erb :index
end

get '/page/?:page?' do
  @deal = Deal.find(:all, 
  :limit => 20, 
  :offset => params[:page].to_i*20,  
  :order => 'id DESC')
  @title = '今日最新'
  @next = request.path.gsub(/\/(\d+)?$/, '') + '/' + ((params[:page]||'1').to_i + 1).to_s
  erb :index
end

get '/catlog/:catlog_id/:name/?:page?' do
  @deal = Deal.find(:all, 
  :limit => 20, 
  :offset => params[:page].to_i*20,
  :conditions => ["catlog = ?", "#{params[:catlog_id]}"],  
  :order => 'id DESC')
  @title =  params[:name]
  @next = request.path.gsub(/\/(\d+)?$/, '') + '/' + ((params[:page]||'1').to_i + 1).to_s
  erb :catlog
end

get '/site/:name/?:page?' do
  @deal = Deal.find(:all, 
  :limit => 20, 
  :offset => params[:page].to_i*20,
  :conditions => ["blink like ?", "%#{params[:name]}%"],  
  :order => 'id DESC')
  @title =  params[:name]
  @next = request.path.gsub(/\/(\d+)?$/, '') + '/' + ((params[:page]||'1').to_i + 1).to_s
  erb :site
end

get '/promotion/?:page?' do

  @deal = Deal.title_like("促销活动").all :limit => 20, :order => 'id DESC', :offset => params[:page].to_i*20
  @title = '促销活动'
  @next = request.path.gsub(/\/(\d+)?$/, '') + '/' + ((params[:page]||'1').to_i + 1).to_s
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

get '/coupons/?:page?' do
  @deal = Deal.find(:all, 
  :conditions => {:deal_site_id => 15},
  :limit => 20,
  :offset => params[:page].to_i*20,
  :order => 'id DESC')
  @title = '优惠券'
  @next = request.path.gsub(/\/(\d+)?$/, '') + '/' + ((params[:page]||'1').to_i + 1).to_s
  erb :coupons
  #cache( erb( :pname ))
end


get '/brand/:name/?:page?' do
  @deal = Deal.find(:all, 
  :conditions => ["brand like ?", "%#{params[:name]}%"],
  :limit => 20, 
  :offset => params[:page].to_i*20,
  :order => 'id DESC')
  @title = params[:name]
  @next = request.path.gsub(/\/(\d+)?$/, '') + '/' + ((params[:page]||'1').to_i + 1).to_s
  erb :brand
  #cache( erb( :brand ))
end

get '/pname/:name/?:page?' do
  @deal = Deal.find(:all, 
  :conditions => ["pname like ?", "%#{params[:name]}%"],
  :limit => 20, 
  :offset => params[:page].to_i*20,
  :order => 'id DESC')
  @title = params[:name]
  @next = request.path.gsub(/\/(\d+)?$/, '') + '/' + ((params[:page]||'1').to_i + 1).to_s
  erb :pname
  #cache( erb( :pname ))
end

get '/model/:model/?:page?' do
  @deal = Deal.find(:all, 
  :conditions => ["model like ?", "%#{params[:model]}%"],
  :limit => 20, 
  :offset => params[:page].to_i*20,
  :order => 'id DESC')
  @title = params[:model]
  @next = request.path.gsub(/\/(\d+)?$/, '') + '/' + ((params[:page]||'1').to_i + 1).to_s
  erb :model
  #cache( erb( :model ))
end

get '/china/?:page?' do
  @deal = Deal.find(:all,
  :conditions => "country = 1",
  :limit => 20, 
  :offset => params[:page].to_i*20,
  :order => 'id DESC')
  @title = '国内购'
  @next = request.path.gsub(/\/(\d+)?$/, '') + '/' + ((params[:page]||'1').to_i + 1).to_s
  erb :china
end

get '/usa/?:page?' do
  @deal = Deal.find(:all,
  :conditions => "country = 2",
  :limit => 20, 
  :offset => params[:page].to_i*20,
  :order => 'id DESC')
  @title = '海外购'
  @next = request.path.gsub(/\/(\d+)?$/, '') + '/' + ((params[:page]||'1').to_i + 1).to_s
  erb :usa
end


################## API路由 ######################


puts '加载路由与控制器'
get '/api/feed/:offset' do
  deal = Deal.find(:all,
  :limit => 10,
  :offset => params[:offset].to_i||0,
  :order => 'id DESC')
  deal.to_json
end

get '/api/feed/country/:id/:offset' do
  deal = Deal.find(:all,
  :limit => 10,
  :conditions => ["country = ?", "#{params[:id]}"],
  :offset => params[:offset].to_i||0,
  :order => 'id DESC')
  deal.to_json
end


get '/api/feed/catlog/:id/:offset' do
  deal = Deal.find(:all, 
  :limit => 10, 
  :conditions => ["catlog = ?", "#{params[:id]}"], 
  :offset => params[:offset].to_i||0,
  :order => 'id DESC')
  deal.to_json
end

get '/api/feed/mall/:id/:offset' do
  deal = Deal.find(:all, 
  :limit => 10, 
  :conditions => ["blink like ?", "%#{params[:id]}%"], 
  :offset => params[:offset].to_i||0,
  :order => 'id DESC')
  deal.to_json
end

#貌似没啥用，先放着：
# ActiveRecord::Base.clear_active_connections!