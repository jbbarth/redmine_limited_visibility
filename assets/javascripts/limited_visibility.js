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
  if($('input#role_limit_visibility').is(":checked")){
    $('.permissions_tab').hide();
    $('.visibility_tab').show();
  }
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


  //when clicking visibility roles in issues/show, move to issue edition
  $('#list_of_involved_roles_per_issue .role').on('click', function() {
    showAndScrollTo("update", "issue_notes")
  })
});

//disable last role so user cannot cut visibility to himself
function disable_role_which_cant_be_removed() {
  /* Temporary disable this feature # client do not want it for now
  //disable last remaining role
  if ($('#involved-roles-form .role.involved.mine').length !== 1) {
    $('#involved-roles-form .role.mine').removeClass('disabled');
  } else {
    $('#involved-roles-form .role.involved.mine').addClass('disabled');
  }
  //disable current role if any
  if ($('#current-role').length == 1) {
    $('[data-role-id='+$('#current-role').val()+']').addClass('disabled')
  }
  */
}

function update_assigned_to_options() {
  $('#involved-roles-form .role').each(function() {
    var element = $(this);
    var option = $('#issue_assigned_to_id option[value="function-'+element.data('role-id')+'"]');
    if (element.hasClass('involved')){
      // option.removeAttr("disabled");
      option.show();
    }else{
      // option.attr("disabled", "disabled");
      option.removeAttr("selected");
      option.hide();
    }
  });
}

function toggle_autochecked_checkboxes() {
  if ($("select#autocheck_mode").val() == 1){
    // autochecked_by_user_function: hide autocheck checkboxes by tracker
    $('.autocheck_checkbox').hide();
  } else {
    $('.autocheck_checkbox').show();
  }
}

//add a mirroring between selected visibility roles and
//the "#authorized_viewers" hidden field => |1|4|5|...
$(function() {
  //bubble up to 'p#involve-roles' to avoid perf issues (not measured, but let's be careful)
  $('#content').on('click', '.role', function() {
    if (!$(this).hasClass('disabled')){
      $(this).toggleClass('involved');
      var authorized = [];
      $('#involved-roles-form .role.involved').each(function() {
        authorized.push($(this).data('role-id'))
      });
      $('#authorized_viewers').val('|' + authorized.join('|') + '|');

      // Update disabled class
      disable_role_which_cant_be_removed();

      // Update assigned_to select options so user can't assigned to a role which has no visibility
      update_assigned_to_options();
    }

  });

  $("select#autocheck_mode").on("change", toggle_autochecked_checkboxes);
  toggle_autochecked_checkboxes();

  //disable eventual last remaining role
  disable_role_which_cant_be_removed();

  update_assigned_to_options();

});
