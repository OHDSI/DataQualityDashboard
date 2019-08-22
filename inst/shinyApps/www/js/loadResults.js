function loadResults(results) {
    $('dq-metadata-heading').attr('data-results', JSON.stringify(results));
    $('dq-dashboard').attr('data-results', JSON.stringify(results.CheckResults));
    $('dq-metadata').attr('data-results', JSON.stringify(results.Metadata[0]));

    function format(d) {
        errorMessage = '';
        if (d.ERROR) {
            errorMessage = d.ERROR;
        }
        return '<table class="dtDetails" style="padding-left:25px;">' +
            '<tr>' +
            '<td>Name:</td>' +
            '<td>' + d.CHECK_NAME + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Description:</td>' +
            '<td>' + d.CHECK_DESCRIPTION + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Level:</td>' +
            '<td>' + d.CHECK_LEVEL + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td># Rows Violated:</td>' +
            '<td>' + d.NUM_VIOLATED_ROWS + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>% Rows Violated:</td>' +
            '<td>' + d.PCT_VIOLATED_ROWS + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Execution Time:</td>' +
            '<td>' + d.EXECUTION_TIME + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>SQL Query:</td>' +
            '<td><pre>' + d.QUERY_TEXT + '</pre></td>' +
            '</tr>' +
            '<tr>' +
            '<td>Error Log:</td>' +
            '<td>' + errorMessage + '</td>' +
            '</tr>' +
            '</table>';
    }

    var dtResults = $('#dt-results').DataTable({
        dom: '<B>l<fr<t>ip>',
        buttons: [
            'colvis'
        ],
        data: results.CheckResults,
        initComplete: function () {
            this.api().columns().every(function (d) {
                var column = this;
                if ([0, 6, 7].includes(d))
                    return;
                var select = $('<select><option value=""></option></select>')
                    .appendTo($(column.header()))
                    .on('click', function () {
                        event.cancelBubble = true;
                    })
                    .on('change', function () {
                        var val = $.fn.dataTable.util.escapeRegex(
                            $(this).val()
                        );
                        column
                            .search(val ? '^' + val + '$' : '', true, false)
                            .draw();
                    });

                column.data().unique().sort().each(function (d, j) {
                    select.append('<option value="' + d + '">' + d + '</option>')
                });
            });
        },
        columns: [
            {
                "className": 'details-control',
                "data": null,
                "defaultContent": '',
                "orderable": false
            },
            { data: function (d) { if (d.FAILED == 0) { return "PASS" } else { return "FAIL" } }, title: "STATUS", className: 'dt-body-right' },
            { data: function (d) { return d.CONTEXT ? d.CONTEXT : "None"; }, title: "CONTEXT" },
            { data: "CATEGORY", title: "CATEGORY" },
            { data: function (d) { return d.SUBCATEGORY ? d.SUBCATEGORY : "None" }, title: "SUBCATEGORY" },
            { data: "CHECK_LEVEL", title: "LEVEL" },
            { data: "CHECK_DESCRIPTION", title: "DESCRIPTION", className: "description", width: "40%" },
            { data: function (d) { return d.PCT_VIOLATED_ROWS ? Math.round(d.PCT_VIOLATED_ROWS * 100) + '%' : 'n/a' }, title: "%&nbsp;RECORDS", type: "num-fmt", className: 'dt-body-right', orderable: true }
        ],
        columnDefs: [{
            targets: [0, 1, 2, 3, 4, 5, 6],
            orderable: false
        }]
    });

    // Add event listener for opening and closing details
    $('#dt-results tbody').on('click', 'td.details-control', function () {
        var tr = $(this).closest('tr');
        var row = dtResults.row(tr);

        if (row.child.isShown()) {
            row.child.hide();
            tr.removeClass('shown');
        }
        else {
            // Open this row
            row.child(format(row.data())).show();
            tr.addClass('shown');
        }
    });
}
