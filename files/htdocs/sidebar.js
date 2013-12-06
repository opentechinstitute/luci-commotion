$(document).ready(function(){
  var animTime = 250,
      clickPolice = false;
  
  $(document).on('touchstart click', '.sb-btn', function(){
    if(!clickPolice){
       clickPolice = true;
      
      var currIndex = $(this).index('.sb-btn'),
          targetHeight = $('.sb-content-inner').eq(currIndex).outerHeight();
   
      $('.sb-btn').removeClass('selected');
      $(this).addClass('selected');
      
      $('.sb-content').stop().animate({ height: 0 }, animTime);
      $('.sb-content').eq(currIndex).stop().animate({ height: targetHeight }, animTime);

      setTimeout(function(){ clickPolice = false; }, animTime);
    }
    
  });
  
});
