$(function() 
   $('#flash_notification').hide().delay(500).slideDown('slow', function() {
      $(this).delay(4000).fadeOut();
   });

   $("#flash_notification").live('click', function(){
       $(this).stop().fadeOut();;
   });

});
