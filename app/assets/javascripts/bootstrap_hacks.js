$(document).ready(function(){
  touchFix();
});

function touchFix(){
  $('body')
  .on('touchstart.dropdown', '.dropdown-menu', function (e) {e.stopPropagation();})
  .on('touchstart.dropdown', '.dropdown-submenu', function (e) {e.preventDefault();});
}