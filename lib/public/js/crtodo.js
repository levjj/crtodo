var $tabs;

function S4() {
  return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
}

function UID() {
  return 'z' + S4() + S4() + S4();
}

function todo_open_entry_ui(name, index) {
  return $('<li class="ui-state-default ui-corner-all" />')
    .addClass('todoentry')
    .attr('id', 'open' + index)
    .append($('<b>' + name + '</b>'));
}

function todo_done_entry_ui(name, index) {
  return $('<li class="ui-state-default ui-state-disabled ui-corner-all" />')
    .addClass('todoentry')
    .attr('id', 'done' + index)
    .append($('<b>' + name + '</b>'));
}

function add_todo(todolist, addpanel_input, title) {
  var name = addpanel_input.val();
  $.post('api/' + title + '/open', {todo: name}, function() {
    todolist.append(
      todo_open_entry_ui(name, $('li', todolist).size())
        .fadeIn('slow'));
  });
  addpanel_input.val('');
}

function move_todo(title, todolist, item) {
  var oldindex = item.attr('id');
  var prefix = oldindex.substring(0, 4);
  var newindex = prefix + $('li', todolist).index(item);
  if (oldindex != newindex) {
    item.attr('id', newindex);
    $.post('api/' + title + '/' + prefix + '/' + oldindex.substring(4),
      {newindex: newindex.substring(4), _method: 'put'});
  }
}

function todolist_open_entries_ui(title, data) {
  var todolist = $('<ul class="todolist" />');
  todolist.sortable({
    revert: true,
    stop: function(event, ui) {
      move_todo(title, todolist, ui.item);
    }
  });
  todolist.disableSelection();
  $.each(data, function(i, item) {
    todolist.append(todo_open_entry_ui(item, i));
  });
  return todolist;
}

function todolist_done_entries_ui(title, data) {
  var todolist = $('<ul class="todolist" />');
  todolist.sortable({
    stop: function(event, ui) {
      move_todo(title, todolist, ui.item);
    },
    items: 'li:not(.ui-state-disabled)'
  });
  todolist.disableSelection();
  $.each(data, function(i, item) {
    todolist.append(todo_done_entry_ui(item, i));
  });
  return todolist;
}

function finish_ui(title) {
  return $('<div class="tododrop finish" title="Drop here to complete ToDo" />')
    .droppable({
      hoverClass: 'finish-hover',
      drop: function(event, ui) {
        var index = ui.draggable.attr('id');
        var prefix = index.substring(0,4);
        var todo = $('b', ui.draggable).html();
        ui.draggable.remove();
        $.post('api/' + title + '/' + prefix + '/' + index.substring(4),
          {_method: 'put'},
          function(data) {
            $('.expander .todolist').append(
              todo_done_entry_ui(todo, data).fadeIn('slow'));
          });
  	  }
    });
}

function trash_ui(title) {
  return $('<div class="tododrop trash" title="Drop here to delete ToDo" />')
    .droppable({
      hoverClass: 'trash-hover',
      drop: function(event, ui) {
        ui.draggable.detach();
        ui.draggable.fadeOut('slow');
        var index = ui.draggable.attr('id');
        var prefix = index.substring(0,4);
        $.post('api/' + title + '/' + prefix + '/' + index.substring(4),
          {_method: 'delete'});
  	  }
    });
}

function addpanel_ui(title, todolist) {
  var addpanel_input = $('<input type="text" class="todoinput" />');
  var addpanel_button = $('<button>Add</button>');
  addpanel_input.keypress(function(event) {
    if (event.keyCode == '13') {
      event.preventDefault();
      add_todo(todolist, addpanel_input, title);
    }
  });
  addpanel_button.click(function() {
    add_todo(todolist, addpanel_input, title);
  });
  return $('<div />')
    .append(addpanel_input)
    .append(addpanel_button);
}

function todolist_open_ui(title, data) {
  var todolist = todolist_open_entries_ui(title, data);
  return $('<div class="ui-corner-all todogroup ui-widget-content" />')
    .append(todolist)
    .append(addpanel_ui(title, todolist));
}

function todolist_done_link_ui() {
  return $('<a href="#">History...</a>')
    .click(function() {
      $('.todogroup', $(this).parent()).slideToggle('slow');
      return false;
    });
}

function todolist_done_list_ui(title, data) {
  return $('<div class="ui-corner-all todogroup ui-widget-content" />')
    .append(todolist_done_entries_ui(title, data))
	.hide();
}

function todolist_done_ui(title, data) {
  return $('<div class="expander" />')
    .append(todolist_done_link_ui())
    .append(todolist_done_list_ui(title, data));
}

function todolist_admin_link_ui() {
  return $('<a href="#">Manage...</a>')
    .click(function() {
      $('p', $(this).parent()).slideToggle('slow');
      return false;
    });
}

function rename_list(title, button) {
  $.post('api/' + title,
    {newname: $('input', $(button).parent()).val(), _method: 'put'},
    function(data) { reload_and_switch_to(data); });
}

function delete_list(title) {
  $.post('api/' + title, { _method: 'delete'},
    function() { reload_and_switch_to_last(); });
}

function todolist_admin_form_ui(title) {
  return $('<p class="ui-widget-content ui-corner-all" />')
    .append($('<input type="text" />').val(title))
    .append($('<br />'))
    .append($('<button>Rename</button>')
      .click(function() { rename_list(title, this); }))
    .append($('<button>Delete</button>')
      .click(function() { delete_list(title); }))
    .hide();
}

function todolist_admin_ui(title) {
  return $('<div class="expander" />')
    .append(todolist_admin_link_ui())
    .append(todolist_admin_form_ui(title));
}

function init_todolist(panel, title) {
  $.getJSON('api/' + title + '/open', function(opendata) {
    $.getJSON('api/' + title + '/done', function(donedata) {
      panel
        .html('')
        .append($('<div class="left"/>')
          .append(todolist_open_ui(title, opendata))
          .append(todolist_done_ui(title, donedata))
          .append(todolist_admin_ui(title)))
        .append($('<div class="right" />')
          .append(finish_ui(title))
          .append(trash_ui(title)))
        .append($('<div class="footer" />'));
    });
  });
}

function addlist() {
  $.post('api/',
    {list: $('#add input').val()},
    function(data) { reload_and_switch_to(data); });
}

function tab_item_ui(item) {
  var listid = '#' + UID();
  $tabs.tabs('add', listid, item);
  $(listid).html('Loading <b>' + item + '</b> ...');
  $('a[href="' + listid + '"]').attr('title', item);
}

function addlist_ui() {
  $tabs.tabs('add', '#add', '<b>New List</b>');
  $('#add').html('New Name: <input type="text" class="todoinput" />' +
                 '<button>Add</button>');
  $('#add input').keypress(function(event) {
    if (event.keyCode == '13') {
      event.preventDefault();
      addlist();
    }
  });
  $('#add button').click(function() { addlist(); });
}

function delete_tabs() {
  while ($tabs.tabs('length') > 0) {
    $tabs.tabs('remove', 0);
  }
}


function reload(oncomplete) {
  $.getJSON('api/', function(data) {
    delete_tabs();
    $.each(data, function(i, item) {
      tab_item_ui(item);
    });
    addlist_ui();
    oncomplete();
  });
}

function reload_and_switch_to(title) {
  reload(function() {
    var link = $('a[title="' + title + '"]');
    var myid = link.attr('href');
    $tabs.tabs('option', 'selected', myid);
  });
}

function reload_and_switch_to_last() {
  reload(function() {
    $tabs.tabs('select', -1);
  });
}

$(document).ready(function() {
  $tabs = $('#main').tabs();
  $tabs.bind('tabsselect', function(event, ui) {
    if (ui.index < $tabs.tabs('length') - 1) {
      init_todolist($(ui.panel), $(ui.tab).attr('title'));
    }
  });
  reload_and_switch_to_last();
});
