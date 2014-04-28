/* Limited visibility plugin javascripts */
function toggleVisibilityForms(id) {
    var role_id = "#role-"+id
    var $texts = $(role_id+"-roles,"+role_id+"-members")
    //=> doesn't work with forms, don't know why ... :/
    $texts.toggle(0, function(){
        var $forms = $(role_id+"-roles-form,"+role_id+"-members-form")
        if ($texts.is(":visible")) { $forms.hide() }
        else { $forms.show() }
    })
}

$(function() {
  $('input#role_limit_visibility').on("change", function() {
    if($(this)[0].checked){
      $('.permissions_tab').hide();
      $('.visibility_tab').show();
    }else{
      $('.permissions_tab').show();
      $('.visibility_tab').hide();
    }
  });

  var query_form_has_been_submitted = false;
  $('#filters-table').bind("DOMSubtreeModified propertychange",function(){
    // On load, disable the checkbox
    if (query_form_has_been_submitted == false) {
      $('#cb_authorized_viewers').attr("disabled", true);
    }
  });
  $('#query_form').submit(function() {
    // On form submit, enable 'authorized_viewers' field so it is take into account
    query_form_has_been_submitted = true;
    $("#cb_authorized_viewers").removeAttr("disabled");
  });
});
