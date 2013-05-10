;(function($) {


$(document).ready(function() {
  // example:
  //$('.cbi-value-title').eq(0).addClass('tippable').data('tip', 'This is a tooltip');
  $('.cbi-value-title').each(function(el) {
    if($(this).data('tip')) {
      $(this).after('<p class="tip">' + $(this).data('tip') + '</p>')
    }
  });
  $('.tippable').on('click', function(ev) { $(this).next('p').toggle() });
  $('header nav > ul').setup_navigation();
  if ($('#navtoselect li').length > 0) {
    selectnav('navtoselect');
  }
});

$.extend($.fn, {
  // via http://simplyaccessible.com/examples/css-menu/option-3/
  setup_navigation: function(settings) {
    settings = $.extend({
      menuHoverClass: 'focus'
    }, settings);

    // Set tabIndex to -1 so that links can't receive focus until menu is open
    $(this).find('li > a').next('ul').find('a').attr('tabIndex',-1);

    $(this).find('li > a').on('hover', function() {
      $(this).closest('ul').find('.'+settings.menuHoverClass).removeClass(settings.menuHoverClass).find('a').attr('tabIndex',-1);
    });

    $(this).find('li > a').on('focus', function() {
      $(this).closest('ul').find('.'+settings.menuHoverClass).removeClass(settings.menuHoverClass).find('a').attr('tabIndex',-1);
      $(this).next('ul')
        .addClass(settings.menuHoverClass)
        .find('a').attr('tabIndex',0);
    });

    // Hide menu if click or focus occurs outside of navigation
    $(this).find('a').last().keydown(function(e) {
      if (e.keyCode == 9) {
        // If the user tabs out of the navigation hide all menus
        $('.'+settings.menuHoverClass).removeClass(settings.menuHoverClass).find('a').attr('tabIndex',-1);
      }
    });
    $(document).click(function() {
      $('.'+settings.menuHoverClass).removeClass(settings.menuHoverClass).find('a').attr('tabIndex',-1);
    });

    $(this).click(function(e) {
      e.stopPropagation();
    });
  }
});

})(Zepto);
