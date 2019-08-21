<<<<<<< HEAD
function loadResults(results) {
    $('dq-metadata-heading').attr('data-results', JSON.stringify(results));
    $('dq-dashboard').attr('data-results', JSON.stringify(results.CheckResults));

    checksCompleteness = { 'checks': results.CheckResults.filter(d => d.CATEGORY == 'Completeness' && d.FAILED == 1) };
    $('#dq-checks-completeness').attr('data-results', JSON.stringify(checksCompleteness));

    checksPlausibility = { 'checks': results.CheckResults.filter(d => d.CATEGORY == 'Plausibility' && d.FAILED == 1) };
    $('#dq-checks-plausibility').attr('data-results', JSON.stringify(checksPlausibility));

    checksConformance = { 'checks': results.CheckResults.filter(d => d.CATEGORY == 'Conformance' && d.FAILED == 1) };
    $('#dq-checks-conformance').attr('data-results', JSON.stringify(checksConformance));

    $('dq-metadata').attr('data-results', JSON.stringify(results.Metadata[0]));

    function format(d) {
        errorMessage = '';
        if (d.ERROR) {
            errorMessage = d.ERROR;
        }
        return '<table cellpadding="3" cellspacing="0" border="0" style="padding-left:50px;">' +
            '<tr>' +
            '<td>Name:</td>' +
            '<td>' + d.CHECK_NAME + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Description:</td>' +
            '<td>' + d.CHECK_DESCRIPTION + '</td>' +
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
        dom: 'B<fr<t>ip>',
        buttons: [
            'colvis'
        ],
        data: results.CheckResults,
        initComplete: function () {
            this.api().columns().every(function (d) {
                var column = this;
                if ([0, 6, 7].includes(d))
                    return;
                console.log(column.footer());
                var select = $('<select><option value=""></option></select>')
                    .appendTo($(column.footer()))
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
                "orderable": false,
                "data": null,
                "defaultContent": ''
            },
            { data: function (d) { return d.CONTEXT ? d.CONTEXT : "None"; }, title: "CONTEXT" },
            { data: "CATEGORY", title: "CATEGORY", searchable: true },
            { data: function (d) { return d.SUBCATEGORY ? d.SUBCATEGORY : "None" }, title: "SUBCATEGORY" },
            { data: "CDM_TABLE_NAME", title: "TABLE" },
            { data: function (d) { if (d.FAILED == 0) { return "PASSED" } else { return "FAILED" } }, title: "STATUS" },
            { data: function (d) { return d.NUM_VIOLATED_ROWS ? d.NUM_VIOLATED_ROWS : 'n/a' }, title: "# RECORDS", type: "num-fmt" },
            { data: function (d) { return d.PCT_VIOLATED_ROWS ? d.PCT_VIOLATED_ROWS : 'n/a' }, title: "% RECORDS", type: "num-fmt" }
        ]
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
=======
function loadResults (results) {
        $('dq-metadata-heading').attr('data-results', JSON.stringify(results));
        $('dq-dashboard').attr('data-results', JSON.stringify(results.CheckResults));

        checksCompleteness = { 'checks': results.CheckResults.filter(d => d.CATEGORY == 'Completeness' && d.FAILED == 1) };
        $('#dq-checks-completeness').attr('data-results', JSON.stringify(checksCompleteness));

        checksPlausibility = { 'checks': results.CheckResults.filter(d => d.CATEGORY == 'Plausibility' && d.FAILED == 1) };
        $('#dq-checks-plausibility').attr('data-results', JSON.stringify(checksPlausibility));

        checksConformance = { 'checks': results.CheckResults.filter(d => d.CATEGORY == 'Conformance' && d.FAILED == 1) };
        $('#dq-checks-conformance').attr('data-results', JSON.stringify(checksConformance));

        $('dq-metadata').attr('data-results', JSON.stringify(results.Metadata[0]));
    }
>>>>>>> 8879eb1de03cdfcfe71bdd91df7a097b56e2750b
