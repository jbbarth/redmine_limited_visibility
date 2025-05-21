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
    if ($('#issue-form').length >= 1){
      showAndScrollTo("update", "issue_notes")
    }
  })
});

function init_issue_form_with_visibility() {
  // Update disabled class on last remaining role
  disable_role_which_cant_be_removed();
  // Update assigned_to select options so user can't assigned to a role which has no visibility
  update_assigned_to_options();
}

//disable last role so user cannot cut visibility to himself
function disable_role_which_cant_be_removed() {
  //disable last remaining role
  if ($('#involved-roles-form .role.involved').length !== 1) {
    $('#involved-roles-form .role').removeClass('disabled');
  } else {
    $('#involved-roles-form .role.involved').addClass('disabled');
  }
  //disable current role if any
  if ($('#current-role').length == 1) {
    $('[data-role-id='+$('#current-role').val()+']').addClass('disabled')
  }
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

  // Hide assignable users if their functions are disabled
  $('#issue_assigned_to_id option').each(function(){
    var user_option = $(this)

    if(user_option.attr('selected') != 'selected'){
        if(user_option.attr('functional_roles') && $('#involved-roles-form .role').length>0){
            // Chrome does not support option <style="display: none;">
            // so we cannot just user_option.hide()
            if (user_option.parent().prop('tagName') === 'SELECT') {
                user_option.wrap('<span style="display: none;" />')
            }

            $('#involved-roles-form .role').each(function() {
                var element = $(this);
                if (element.hasClass('involved')) {
                    if (user_option.attr('functional_roles').split(',').indexOf(element.data('role-id').toString()) >= 0){
                        // cannot just user_option.show()
                        user_option.unwrap('span')
                    }
                }
            })
        }
    }
  })
}

function toggle_autochecked_checkboxes() {
  if ($("select#autocheck_mode").val() == 1){
    // autochecked_by_user_function: hide autocheck checkboxes by tracker
    $('#autocheck_functions_per_function').show();
    $('#autocheck_functions_per_tracker').hide();
  } else {
    $('#autocheck_functions_per_function').hide();
    $('#autocheck_functions_per_tracker').show();
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

      init_issue_form_with_visibility()
    }

  });

  $("select#autocheck_mode").on("change", toggle_autochecked_checkboxes);
  toggle_autochecked_checkboxes();

  init_issue_form_with_visibility()

});

//////
// Adapt updateIssueFrom core function: reset visibility to default (based on new project or tracker)
//
function updateIssueAndResetVisibilityFrom(url, el) {
  $('#all_attributes input, #all_attributes textarea, #all_attributes select').each(function(){
    $(this).data('valuebeforeupdate', $(this).val());
  });
  if (el) {
    $("#form_update_triggered_by").val($(el).attr('id'));
  }
  return $.ajax({
    url: url,
    type: 'post',
    data: $($("#issue-form")[0].elements).not("#authorized_viewers").serialize()
  });
}

function buildListVisibilityFilterRow(field, operator, values) {
    // Case filterOptions['type'] == 'list_visiblity'

    var fieldId = field.replace('.', '_');
    var filterTable = $("#filters-table");
    var filterOptions = availableFilters[field];
    if (!filterOptions) return;
    var operators = operatorByType[filterOptions['type']];
    var filterValues = filterOptions['values'];
    var i, select;

    var tr = $('<div class="filter">').attr('id', 'tr_' + fieldId).html(
        '<div class="field"><input checked="checked" id="cb_' + fieldId + '" name="f[]" value="' + field + '" type="checkbox"><label for="cb_' + fieldId + '"> ' + filterOptions['name'] + '</label></div>' +
        '<div class="operator"><select id="operators_' + fieldId + '" name="op[' + field + ']"></div>' +
        '<div class="values"></div>'
    );
    filterTable.append(tr);

    select = tr.find('.operator select');
    for (i = 0; i < operators.length; i++) {
        var option = $('<option>').val(operators[i]).text(operatorLabels[operators[i]]);
        if (operators[i] == operator) {
            option.prop('selected', true);
        }
        select.append(option);
    }
    select.change(function () {
            var fieldId = field.replace('.', '_');
            var operator = $("#operators_" + fieldId);
            if (operator.val() == 'mine') {
                enableValues(field, []);
            } else {
                toggleOperator(field);
            }
        }
    );

    tr.find('.values').append(
        '<span style="display:none;"><select class="value" id="values_' + fieldId + '_1" name="v[' + field + '][]"></select>' +
        ' <span class="toggle-multiselect icon-only ' + (values.length > 1 ? 'icon-toggle-minus' : 'icon-toggle-plus') + '">&nbsp;</span></span>'
    );
    select = tr.find('.values select');
    if (values.length > 1) {
        select.attr('multiple', true);
    }
    for (i = 0; i < filterValues.length; i++) {
        var filterValue = filterValues[i];
        var option = $('<option>');
        if ($.isArray(filterValue)) {
            option.val(filterValue[1]).text(filterValue[0]);
            if ($.inArray(filterValue[1], values) > -1) {
                option.prop('selected', true);
            }
            if (filterValue.length == 3) {
                var optgroup = select.find('optgroup').filter(function () {
                    return $(this).attr('label') == filterValue[2]
                });
                if (!optgroup.length) {
                    optgroup = $('<optgroup>').attr('label', filterValue[2]);
                }
                option = optgroup.append(option);
            }
        } else {
            option.val(filterValue).text(filterValue);
            if ($.inArray(filterValue, values) > -1) {
                option.prop('selected', true);
            }
        }
        select.append(option);
    }

}
