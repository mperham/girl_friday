Update = (function() {
  function Update(dom_id, seconds) {
    this.dom_id = dom_id;
    this.milleseconds = seconds * 1000; 
  };

  Update.prototype.note = function(busy, pool_size, backlog) {
    var s = "OK";
    if (busy == pool_size && backlog < pool_size) {
      s = "Busy";
    } 
    if(busy ==  pool_size && backlog >= pool_size) {
      s = "Busy and Backlogged"
    }
    return s;
  };

  Update.prototype.check = function() {
    dom_id = this.dom_id;
    that = this;
    setInterval(function() {
      $.getJSON('status.json',
                function(data) {
                  $.each(data, function(name, info) {
                    var selector = ["#", dom_id, " tbody tr#", name].join('');
                    var row = $(selector);
                    $('.name', row).html(name);
                    $('.pool_size', row).html(info.pool_size);
                    $('.busy', row).html(info.busy);
                    $('.backlog', row).html(info.backlog);
                    note = that.note(info.busy, info.pool_size, info.backlog);
                    $('.note', row).html(note);
                    if(/backlogged/i.test(note)) {
                      row.attr('class', 'busy-and-backlogged-bg');
                    } else if(/busy/i.test(note)) {
                      row.attr('class', 'busy-bg');
                    } else {
                      row.removeAttr('class');
                    }
                  });
                }
        )
    }, this.milleseconds);
  }
  return Update;
})();

$.fn.update_rows = function(seconds) {
  return this.each(function() { (new Update(this.id, seconds)).check() });
};

$().ready(function() {
  // update every second
  $('#queues').update_rows(1);
});
