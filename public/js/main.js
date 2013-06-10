var title = window.document.title;
var reg = /(,*)-/;
var channel = title.match(reg)[1];
$('#top a').map(){
	$(this :contains(channel)).css('color','#333').attr('#')
}