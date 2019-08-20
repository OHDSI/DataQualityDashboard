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