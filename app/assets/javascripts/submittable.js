$('.submittable').live('change', 
  function() {
    $(this).parents('form:first').submit();
  }
);  
