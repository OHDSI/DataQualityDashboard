function loadResults(results) {
    $('dq-metadata-heading').attr('data-results', JSON.stringify(results));
    $('dq-dashboard').attr('data-results', JSON.stringify(results.CheckResults));

    var metadata = results.Metadata[0];
    $('cdm-source-name').text(metadata.cdmSourceName);
    $('dq-metadata').attr('data-results', JSON.stringify(metadata));

    function format(d) {
        errorMessage = '';
        thresholdMessage = ''
        if (d.thresholdValue != undefined) {
            thresholdMessage = ' (Threshold=' + d.thresholdValue + '%)';
        }
        if (d.notesValue == undefined) {
            d.notesValue = '';
        }
        if (d.conceptId == undefined) {
            d.conceptId = '';
        }
        if (d.unitConceptId == undefined) {
            d.unitConceptId = '';
        }
        if (d.cdmFieldName == undefined) {
            d.cdmFieldName = '';
        }
        if (d.error) {
            errorMessage = d.error;
        }
        return '<table class="dtDetails" style="padding-left:25px;">' +
            '<tr>' +
            '<td>Name:</td>' +
            '<td>' + d.checkName + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Description:</td>' +
            '<td>' + d.checkDescription + thresholdMessage + '.</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Notes:</td>' +
            '<td>' + d.notesValue + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Level:</td>' +
            '<td>' + d.checkLevel + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Table:</td>' +
            '<td>' + d.cdmTableName + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Field:</td>' +
            '<td>' + d.cdmFieldName + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Concept Id:</td>' +
            '<td>' + d.conceptId + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Unit Concept Id:</td>' +
            '<td>' + d.unitConceptId + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Check Id:</td>' +
            '<td>' + d.checkId + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td># Rows Violated:</td>' +
            '<td>' + d.numViolatedRows + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>% Rows Violated:</td>' +
            '<td>' + (d.pctViolatedRows * 100).toFixed(2) + '%' + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td># Denominator Rows:</td>' +
            '<td>' + d.numDenominatorRows + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Execution Time:</td>' +
            '<td>' + d.executionTime + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>Not applicable reason:</td>' +
            '<td>' + d.notApplicableReason + '</td>' +
            '</tr>' +
            '<tr>' +
            '<td>SQL Query:</td>' +
            '<td><pre>' + d.queryText + '</pre></td>' +
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
            {
                extend: 'csv',
                filename: 'dqd_results',
                text: 'Export',
                header: true,
                exportOptions: {
                    // All but the first (empty) column
                    columns: [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ],
                    // Header without drop down options
                    format: {
                        header: function(innerHTML, index, node) {
                            return innerHTML.replace(/<.+/, '').replace(/&nbsp;/g, ' ');
                        }
                    }
                }
            }
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
            { data: function (d) { if (d.isError == 1) { return "ERROR" } else if (d.notApplicable == 1) { return "NOT APPLICABLE" } else if (d.failed == 1) { return "FAIL" } else {return "PASS"} }, title: "STATUS", className: 'dt-body-right' },
            /*{ data: function (d) { return d.context ? d.context : "None"; }, title: "CONTEXT" },*/
            { data: "cdmTableName", title: "TABLE"},
            { data: function (d) { return d.cdmFieldName ? d.cdmFieldName : "None"; }, title: "FIELD", visible: false },
            { data: "checkName", title: "CHECK", visible: false},
            { data: "category", title: "CATEGORY" },
            { data: function (d) { return d.subcategory ? d.subcategory : "None" }, title: "SUBCATEGORY" },
            { data: "checkLevel", title: "LEVEL" },
            { data: function (d) { if (d.notesValue == null) { return "None"; } else { return "Exists"; } }, title: "NOTES" },
            
            {
                data: function (d) {
                    thresholdMessage = '';
                    if (d.thresholdValue != undefined) {
                        thresholdMessage = ' (Threshold=' + d.thresholdValue + '%).';
                    }
                    return d.checkDescription + thresholdMessage;
                }, title: "DESCRIPTION", className: "description", width: "40%"
            },
            { data: function (d) { return d.pctViolatedRows ? (d.pctViolatedRows * 100).toFixed(2) + '%' : '0%' }, title: "%&nbsp;RECORDS", type: "num-fmt", className: 'dt-body-right', orderable: true }
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
