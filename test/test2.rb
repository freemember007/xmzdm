require 'rubygems'
require 'open-uri'

#获取跳转后的地址
blink = "http://www.amazon.com/gp/product/B0032UXG3I/ref=as_li_ss_tl?ie=UTF8&tag=http4040-20&linkCode=as2&camp=1789&creative=390957&creativeASIN=B0032UXG3I"
blink = open(URI.encode(blink)).base_uri.to_s
puts blink

#跳两次能解决此问题吗？

#link = "http://s.click.taobao.com/t_js?tu=http%3A%2F%2Fs.click.taobao.com%2Ft_8%3Fe%3D7HZ6jHSTbIA%252BrjJuOrlhS5YKYGRd7gsoucPzXw1xjOAdFg%253D%253D%26p%3Dmm_29521984_0_0%26ref%3D"

blink = open(URI.encode(blink)).base_uri.to_s
puts blink

#bad uri错误
#link= "http://product.dangdang.com/product.aspx?product_id=60202718&_ddclickunion=P-295759|ad_type=10|sys_id=1"

#非直接地址的截取
blink = URI.decode(URI.decode(blink).gsub(/(http.*=)?(http(%3A|:).*)/,'\2'))
puts blink





