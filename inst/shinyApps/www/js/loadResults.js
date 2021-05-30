function loadResults(results) {
    $('dq-metadata-heading').attr('data-results', JSON.stringify(results));
    $('dq-dashboard').attr('data-results', JSON.stringify(results.CheckResults));

    var metadata = results.Metadata[0];
    $('cdm-source-name').text(metadata.CDM_SOURCE_NAME);
    $('dq-metadata').attr('data-results', JSON.stringify(metadata));

    function format(d) {
        errorMessage = '';
        thresholdMessage = ''
        if (d.THRESHOLD_VALUE != undefined) {
            thresholdMessage = ' (Threshold=' + d.THRESHOLD_VALUE + '%)';
        }
        if (d.NOTES_VALUE == undefined) {
            d.NOTES_VALUE = '';
        }
        if (d.CONCEPT_ID == undefined) {
            d.CONCEPT_ID = '';
        }
        if (d.UNIT_CONCEPT_ID == undefined) {
            d.UNIT_CONCEPT_ID = '';
        }
        if (d.CDM_FIELD_NAME == undefined) {
            d.CDM_FIELD_NAME = '';
        }
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
            '<td>' + d.CHECK_DESCRIPTION + thresholdMessage + '.</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Notes:</td>' +
            '<td>' + d.NOTES_VALUE + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Level:</td>' +
            '<td>' + d.CHECK_LEVEL + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Table:</td>' +
            '<td>' + d.CDM_TABLE_NAME + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Field:</td>' +
            '<td>' + d.CDM_FIELD_NAME + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Concept Id:</td>' +
            '<td>' + d.CONCEPT_ID + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Unit Concept Id:</td>' +
            '<td>' + d.UNIT_CONCEPT_ID + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Check Id:</td>' +
            '<td>' + d.checkId + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td># Rows Violated:</td>' +
            '<td>' + d.NUM_VIOLATED_ROWS + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>% Rows Violated:</td>' +
            '<td>' + (d.PCT_VIOLATED_ROWS * 100).toFixed(2) + '%' + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td># Denominator Rows:</td>' +
            '<td>' + d.NUM_DENOMINATOR_ROWS + '</td>' +
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
        lengthMenu: [[5, 10, -1], [5, 10, "All"]],
        order: [[10, "desc"]],
        buttons: [
            'colvis',
            'csvHtml5'
        ],
        data: results.CheckResults,
        initComplete: function () {
            this.api().columns().every(function (d) {
                var column = this;
                if ([0, 9, 10].includes(d))
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
                "defaultContent": ''
            },
            { data: function (d) { if (d.FAILED == 0) { return "PASS" } else { return "FAIL" } }, title: "STATUS", className: 'dt-body-right' },
            /*{ data: function (d) { return d.CONTEXT ? d.CONTEXT : "None"; }, title: "CONTEXT" },*/
            { data: "CDM_TABLE_NAME", title: "TABLE"},
            { data: function (d) { return d.CDM_FIELD_NAME ? d.CDM_FIELD_NAME : "None"; }, title: "FIELD", visible: false },
            { data: "CHECK_NAME", title: "CHECK", visible: false},
            { data: "CATEGORY", title: "CATEGORY" },
            { data: function (d) { return d.SUBCATEGORY ? d.SUBCATEGORY : "None" }, title: "SUBCATEGORY" },
            { data: "CHECK_LEVEL", title: "LEVEL" },
            { data: function (d) { if (d.NOTES_VALUE == null) { return "None"; } else { return "Exists"; } }, title: "NOTES" },
            
            {
                data: function (d) {
                    thresholdMessage = '';
                    if (d.THRESHOLD_VALUE != undefined) {
                        thresholdMessage = ' (Threshold=' + d.THRESHOLD_VALUE + '%).';
                    }
                    return d.CHECK_DESCRIPTION + thresholdMessage;
                }, title: "DESCRIPTION", className: "description", width: "40%"
            },
            { data: function (d) { return d.PCT_VIOLATED_ROWS ? (d.PCT_VIOLATED_ROWS * 100).toFixed(2) + '%' : '0%' }, title: "%&nbsp;RECORDS", type: "num-fmt", className: 'dt-body-right', orderable: true }
        ],
        columnDefs: [{
            targets: [0, 1, 2, 3, 4, 5, 6],
            orderable: true
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
