function HideContent(d) {
document.getElementById(d).style.display = "none";
}
function ShowContent(d) {
document.getElementById(d).style.display = "block";
}
function ReverseDisplay(d) {
if(document.getElementById(d).style.display == "none") { document.getElementById(d).style.display = "block"; }
else { document.getElementById(d).style.display = "none"; }
}
Zepto(function($){
  $('.app-canvas').each(function(el) {
    if($(this).data('tip')) {
      $(this).parent().after('<p class="tip">' + $(this).data('tip') + '</p>')
    }
  });
  $('.app-tippable').on('click', function(ev) { $(this).parent().next('p').toggle() });
});