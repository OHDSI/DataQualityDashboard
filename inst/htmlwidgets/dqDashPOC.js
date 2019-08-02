HTMLWidgets.widget({
  name: 'dqDashPOC',
  type: 'output',
  factory: function (el, width, height) {
    return {
      renderValue: function (data) {
        el.innerHTML = `<dq-dashboard data-results='${JSON.stringify(data)}'></dq-dashboard>`;
      },
      resize: function (width, height) {
        // TODO: code to re-render the widget with a new size
      }
    };
  }
});