$(document).ready(function(){
	jQuery.ias({
		container: '#content',
		item: '.deal-item',
		pagination: 'div#page',
		next: 'div#page a:first',
		loader: '<img src="/images/ajax-loader.gif"/>',
		trigger: '点击加载更多...'
	});
});