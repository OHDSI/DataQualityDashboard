class DqDashboard extends HTMLElement {
  static getTemplate() {
    return `
    <style>
        table {
          width: 100%;
          border-collapse: collapse;
        }
        table thead tr td {
            text-align: center;
            color: #fff;
            background-color: #20425a;
            border: 1px solid #ddd;    
        }

        table tbody tr:nth-child(even){
          background-color: #f2f2f2;
        }

        table tbody tr td:first-child{
          color: #fff;
          background-color:#20425a;
        }

        table tbody tr td {
            text-align: right;
            border: 1px solid #ddd;     
        }

        td {
            color: #000;
            padding: 3px 7px 3px 7px;
            font-size: 20px;
        }

        td.overall {
          font-size:28px;
          font-weight: bold;
        }

        td:empty, th:empty {
          border:0;
          background:transparent;
        }

        td.fail {
          color: #C00;
          font-weight:bold;
        }
    </style>

    <table>
        <thead>
            <tr>
                <td></td>
                <td colspan="4">Verification</td>
                <td colspan="4">Validation</td>
                <td colspan="6">Total</td>
            </tr>
            <tr>
                <td></td>
                <td>Pass</td>
                <td>Fail</td>
                <td>Total</td>
                <td>% Pass</td>
                <td>Pass</td>
                <td>Fail</td>
                <td>Total</td>
                <td>% Pass</td>
                <td>Pass</td>
                <td>NA</td>
                <td>Error</td>
                <td>Fail</td>
                <td>Total</td>
                <td>% Pass</td>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Plausibility </td>
                <td>{{Verification.Plausibility.Pass}}</td>
                <td {{#if Verification.Plausibility.Fail}}class="fail"{{/if}}>{{Verification.Plausibility.Fail}}</td>
                <td>{{Verification.Plausibility.Total}}</td>
                <td>{{Verification.Plausibility.PercentPass}}</td>
                <td>{{Validation.Plausibility.Pass}}</td>
                <td {{#if Validation.Plausibility.Fail}}class="fail"{{/if}}>{{Validation.Plausibility.Fail}}</td>
                <td>{{Validation.Plausibility.Total}}</td>
                <td>{{Validation.Plausibility.PercentPass}}</td>
                <td>{{Total.Plausibility.Pass}}</td>
                <td>{{Total.Plausibility.NA}}</td>
                <td>{{Total.Plausibility.Error}}</td>
                <td {{#if Total.Plausibility.Fail}}class="fail"{{/if}}>{{Total.Plausibility.Fail}}</td>                
                <td>{{Total.Plausibility.Total}}</td>
                <td>{{Total.Plausibility.PercentPass}}</td>
            </tr>
            <tr>
                <td>Conformance </td>
                <td>{{Verification.Conformance.Pass}}</td>
                <td {{#if Verification.Conformance.Fail}}class="fail"{{/if}}>{{Verification.Conformance.Fail}}</td>
                <td>{{Verification.Conformance.Total}}</td>
                <td>{{Verification.Conformance.PercentPass}}</td>
                <td>{{Validation.Conformance.Pass}}</td>
                <td {{#if Validation.Conformance.Fail}}class="fail"{{/if}}>{{Validation.Conformance.Fail}}</td>
                <td>{{Validation.Conformance.Total}}</td>
                <td>{{Validation.Conformance.PercentPass}}</td>
                <td>{{Total.Conformance.Pass}}</td>
                <td>{{Total.Conformance.NA}}</td>
                <td>{{Total.Conformance.Error}}</td>
                <td {{#if Total.Conformance.Fail}}class="fail"{{/if}}>{{Total.Conformance.Fail}}</td>                
                <td>{{Total.Conformance.Total}}</td>
                <td>{{Total.Conformance.PercentPass}}</td>
            </tr>
            <tr>
                <td>Completeness </td>
                <td>{{Verification.Completeness.Pass}}</td>
                <td {{#if Verification.Completeness.Fail}}class="fail"{{/if}}>{{Verification.Completeness.Fail}}</td>
                <td>{{Verification.Completeness.Total}}</td>
                <td>{{Verification.Completeness.PercentPass}}</td>
                <td>{{Validation.Completeness.Pass}}</td>
                <td {{#if Validation.Completeness.Fail}}class="fail"{{/if}}>{{Validation.Completeness.Fail}}</td>                
                <td>{{Validation.Completeness.Total}}</td>
                <td>{{Validation.Completeness.PercentPass}}</td>
                <td>{{Total.Completeness.Pass}}</td>
                <td>{{Total.Completeness.NA}}</td>
                <td>{{Total.Completeness.Error}}</td>
                <td {{#if Total.Completeness.Fail}}class="fail"{{/if}}>{{Total.Completeness.Fail}}</td>
                <td>{{Total.Completeness.Total}}</td>
                <td>{{Total.Completeness.PercentPass}}</td>
            </tr>
            <tr>
                <td>Total </td>
                <td>{{Verification.Total.Pass}}</td>
                <td {{#if Verification.Total.Fail}}class="fail"{{/if}}>{{Verification.Total.Fail}}</td>
                <td>{{Verification.Total.Total}}</td>
                <td>{{Verification.Total.PercentPass}}</td>
                <td>{{Validation.Total.Pass}}</td>
                <td {{#if Validation.Total.Fail}}class="fail"{{/if}}>{{Validation.Total.Fail}}</td>
                <td>{{Validation.Total.Total}}</td>
                <td>{{Validation.Total.PercentPass}}</td>
                <td>{{Total.Total.Pass}}</td>
                <td>{{Total.Total.NA}}</td>
                <td>{{Total.Total.Error}}</td>
                <td {{#if Total.Total.Fail}}class="fail"{{/if}}>{{Total.Total.Fail}}</td>                
                <td>{{Total.Total.Total}}</td>
                <td class="overall">{{Total.Total.PercentPass}}</td>
            </tr>
        </tbody>
    </table>
    `;
  }

  connectedCallback() {
    this.root = this.attachShadow({ mode: 'open' });
    this.render();
  }

  static get observedAttributes() {
    return ['data-results'];
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (this.root && oldValue !== newValue) {
      this.render();
    }
  }

  get results() {
    return JSON.parse(this.getAttribute('data-results'));
  }

  render() {
    if (!this.results || !Array.isArray(this.results))
      return;

    // Verification Plausibility
    const VerificationPlausibilityPass = this.results.filter(
      c => (c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0) &&
        c.CONTEXT == "Verification"
        && c.CATEGORY == "Plausibility"
    ).length;

    const VerificationPlausibilityFail = this.results.filter(
      c => c.FAILED == 1 &&
        c.CONTEXT == "Verification"
        && c.CATEGORY == "Plausibility"
    ).length;

    const VerificationPlausibilityTotal = this.results.filter(
      c => c.CONTEXT == "Verification"
        && c.CATEGORY == "Plausibility"
    ).length;

    const VerificationPlausibilityPercentPass = VerificationPlausibilityTotal == 0 ? "-" : Math.round(VerificationPlausibilityPass / (VerificationPlausibilityPass + VerificationPlausibilityFail) * 100) + "%";

    // Verification Conformance
    const VerificationConformancePass = this.results.filter(
      c => (c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0) &&
        c.CONTEXT == "Verification"
        && c.CATEGORY == "Conformance"
    ).length;

    const VerificationConformanceFail = this.results.filter(
      c => c.FAILED == 1 &&
        c.CONTEXT == "Verification"
        && c.CATEGORY == "Conformance"
    ).length;

    const VerificationConformanceTotal = this.results.filter(
      c => c.CONTEXT == "Verification"
        && c.CATEGORY == "Conformance"
    ).length;

    const VerificationConformancePercentPass = VerificationConformanceTotal == 0 ? "-" : Math.round(VerificationConformancePass / (VerificationConformancePass + VerificationConformanceFail) * 100) + "%";

    // Verification Completeness
    const VerificationCompletenessPass = this.results.filter(
      c => (c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0) &&
        c.CONTEXT == "Verification"
        && c.CATEGORY == "Completeness"
    ).length;

    const VerificationCompletenessFail = this.results.filter(
      c => c.FAILED == 1 &&
        c.CONTEXT == "Verification"
        && c.CATEGORY == "Completeness"
    ).length;

    const VerificationCompletenessTotal = this.results.filter(
      c => c.CONTEXT == "Verification"
        && c.CATEGORY == "Completeness"
    ).length;

    const VerificationCompletenessPercentPass = VerificationCompletenessTotal == 0 ? "-" : Math.round(VerificationCompletenessPass / (VerificationCompletenessPass + VerificationCompletenessFail) * 100) + "%";

    // Verification Totals
    const VerificationPass = this.results.filter(
      c => (c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0) &&
        c.CONTEXT == "Verification"
    ).length;

    const VerificationFail = this.results.filter(
      c => c.FAILED == 1 &&
        c.CONTEXT == "Verification"
    ).length;

    const VerificationTotal = this.results.filter(
      c => c.CONTEXT == "Verification"
    ).length;

    const VerificationPercentPass = VerificationTotal == 0 ? "-" : Math.round(VerificationPass / (VerificationPass + VerificationFail) * 100) + "%";

    // Validation Plausibility
    const ValidationPlausibilityPass = this.results.filter(
      c => (c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0) &&
        c.CONTEXT == "Validation"
        && c.CATEGORY == "Plausibility"
    ).length;

    const ValidationPlausibilityFail = this.results.filter(
      c => c.FAILED == 1 &&
        c.CONTEXT == "Validation"
        && c.CATEGORY == "Plausibility"
    ).length;

    const ValidationPlausibilityTotal = this.results.filter(
      c => c.CONTEXT == "Validation"
        && c.CATEGORY == "Plausibility"
    ).length;

    const ValidationPlausibilityPercentPass = ValidationPlausibilityTotal == 0 ? "-" : Math.round(ValidationPlausibilityPass / (ValidationPlausibilityPass + ValidationPlausibilityFail) * 100) + "%";

    // Validation Conformance
    const ValidationConformancePass = this.results.filter(
      c => (c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0) &&
        c.CONTEXT == "Validation"
        && c.CATEGORY == "Conformance"
    ).length;

    const ValidationConformanceFail = this.results.filter(
      c => c.FAILED == 1 &&
        c.CONTEXT == "Validation"
        && c.CATEGORY == "Conformance"
    ).length;

    const ValidationConformanceTotal = this.results.filter(
      c => c.CONTEXT == "Validation"
        && c.CATEGORY == "Conformance"
    ).length;

    const ValidationConformancePercentPass = ValidationConformanceTotal == 0 ? "-" : Math.round(ValidationConformancePass / (ValidationConformancePass + ValidationConformanceFail) * 100) + "%";

    // Validation Completeness
    const ValidationCompletenessPass = this.results.filter(
      c => (c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0) &&
        c.CONTEXT == "Validation"
        && c.CATEGORY == "Completeness"
    ).length;

    const ValidationCompletenessFail = this.results.filter(
      c => c.FAILED == 1 &&
        c.CONTEXT == "Validation"
        && c.CATEGORY == "Completeness"
    ).length;

    const ValidationCompletenessTotal = this.results.filter(
      c => c.CONTEXT == "Validation"
        && c.CATEGORY == "Completeness"
    ).length;

    const ValidationCompletenessPercentPass = ValidationCompletenessTotal == 0 ? "-" : Math.round(ValidationCompletenessPass / (ValidationCompletenessPass + ValidationCompletenessFail) * 100) + "%";

    // Validation
    const ValidationPass = this.results.filter(
      c => (c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0) &&
        c.CONTEXT == "Validation"
    ).length;

    const ValidationFail = this.results.filter(
      c => c.FAILED == 1 &&
        c.CONTEXT == "Validation"
    ).length;

    const ValidationTotal = this.results.filter(
      c => c.CONTEXT == "Validation"
    ).length;

    const ValidationPercentPass = ValidationTotal == 0 ? "-" : Math.round(ValidationPass / (ValidationPass + ValidationFail) * 100) + "%";

    // Plausibility
    const PlausibilityPass = this.results.filter(
      c => (c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0) &&
        c.CATEGORY == "Plausibility"
    ).length;
    
    const PlausibilityNA = this.results.filter(
      c => c.NOT_APPLICABLE == 1 &&
        c.CATEGORY == "Plausibility"
    ).length;
    
    const PlausibilityError = this.results.filter(
      c => c.IS_ERROR == 1 &&
        c.CATEGORY == "Plausibility"
    ).length;

    const PlausibilityFail = this.results.filter(
      c => c.FAILED == 1 &&
        c.CATEGORY == "Plausibility"
    ).length;

    const PlausibilityTotal = this.results.filter(
      c => c.CATEGORY == "Plausibility"
    ).length;

    const PlausibilityPercentPass = PlausibilityTotal == 0 ? "-" : Math.round(PlausibilityPass / (PlausibilityPass + PlausibilityFail) * 100) + "%";

    // Conformance
    const ConformancePass = this.results.filter(
      c => (c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0) 
        && c.CATEGORY == "Conformance"
    ).length;

    const ConformanceNA = this.results.filter(
      c => c.NOT_APPLICABLE == 1
        && c.CATEGORY == "Conformance"
    ).length;

    const ConformanceError = this.results.filter(
      c => c.IS_ERROR == 1
        && c.CATEGORY == "Conformance"
    ).length;

    const ConformanceFail = this.results.filter(
      c => c.FAILED == 1
        && c.CATEGORY == "Conformance"
    ).length;

    const ConformanceTotal = this.results.filter(
      c => c.CATEGORY == "Conformance"
    ).length;

    const ConformancePercentPass = ConformanceTotal == 0 ? "-" : Math.round(ConformancePass / (ConformancePass + ConformanceFail) * 100) + "%";

    // Completeness
    const CompletenessPass = this.results.filter(
      c => (c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0)
        && c.CATEGORY == "Completeness"
    ).length;

    const CompletenessNA = this.results.filter(
      c => c.NOT_APPLICABLE == 1
        && c.CATEGORY == "Completeness"
    ).length;

    const CompletenessError = this.results.filter(
      c => c.IS_ERROR == 1
        && c.CATEGORY == "Completeness"
    ).length;

    const CompletenessFail = this.results.filter(
      c => c.FAILED == 1
        && c.CATEGORY == "Completeness"
    ).length;

    const CompletenessTotal = this.results.filter(
      c => c.CATEGORY == "Completeness"
    ).length;

    const CompletenessPercentPass = CompletenessTotal == 0 ? "-" : Math.round(CompletenessPass / (CompletenessPass + CompletenessFail) * 100) + "%";

    // All
    const AllPass = this.results.filter(
      c => c.hasOwnProperty("PASSED") ? c.PASSED == 1 : c.FAILED == 0
    ).length;    
    
    const AllNA = this.results.filter(
      c => c.NOT_APPLICABLE == 1
    ).length;    
    
    const AllError= this.results.filter(
      c => c.IS_ERROR == 1
    ).length;

    const AllFail = this.results.filter(
      c => c.FAILED == 1
    ).length;

    const AllTotal = this.results.length;

    const AllPercentPass = AllTotal == 0 ? "-" : Math.round(AllPass / (AllPass + AllFail) * 100) + "%";

    const derivedResults = {
      "Verification": {
        "Plausibility": {
          "Pass": VerificationPlausibilityPass,
          "Fail": VerificationPlausibilityFail,
          "Total": VerificationPlausibilityTotal,
          "PercentPass": VerificationPlausibilityPercentPass
        },
        "Conformance": {
          "Pass": VerificationConformancePass,
          "Fail": VerificationConformanceFail,
          "Total": VerificationConformanceTotal,
          "PercentPass": VerificationConformancePercentPass
        },
        "Completeness": {
          "Pass": VerificationCompletenessPass,
          "Fail": VerificationCompletenessFail,
          "Total": VerificationCompletenessTotal,
          "PercentPass": VerificationCompletenessPercentPass
        },
        "Total": {
          "Pass": VerificationPass,
          "Fail": VerificationFail,
          "Total": VerificationTotal,
          "PercentPass": VerificationPercentPass
        }
      },
      "Validation": {
        "Plausibility": {
          "Pass": ValidationPlausibilityPass,
          "Fail": ValidationPlausibilityFail,
          "Total": ValidationPlausibilityTotal,
          "PercentPass": ValidationPlausibilityPercentPass
        },
        "Conformance": {
          "Pass": ValidationConformancePass,
          "Fail": ValidationConformanceFail,
          "Total": ValidationConformanceTotal,
          "PercentPass": ValidationConformancePercentPass
        },
        "Completeness": {
          "Pass": ValidationCompletenessPass,
          "Fail": ValidationCompletenessFail,
          "Total": ValidationCompletenessTotal,
          "PercentPass": ValidationCompletenessPercentPass
        },
        "Total": {
          "Pass": ValidationPass,
          "Fail": ValidationFail,
          "Total": ValidationTotal,
          "PercentPass": ValidationPercentPass
        }
      },
      "Total": {
        "Plausibility": {
          "Pass": PlausibilityPass,
          "NA": PlausibilityNA,
          "Error": PlausibilityError,
          "Fail": PlausibilityFail,
          "Total": PlausibilityTotal,
          "PercentPass": PlausibilityPercentPass
        },
        "Conformance": {
          "Pass": ConformancePass,
          "NA": ConformanceNA,
          "Error": ConformanceError,
          "Fail": ConformanceFail,
          "Total": ConformanceTotal,
          "PercentPass": ConformancePercentPass
        },
        "Completeness": {
          "Pass": CompletenessPass,
          "NA": CompletenessNA,
          "Error": CompletenessError,
          "Fail": CompletenessFail,
          "Total": CompletenessTotal,
          "PercentPass": CompletenessPercentPass
        },
        "Total": {
          "Pass": AllPass,
          "NA": AllNA,
          "Error": AllError,
          "Fail": AllFail,
          "Total": AllTotal,
          "PercentPass": AllPercentPass
        }
      }
    }

    const hbTemplate = Handlebars.compile(DqDashboard.getTemplate());
    const html = hbTemplate(derivedResults);
    this.root.innerHTML = html;
  }
}

customElements.define('dq-dashboard', DqDashboard);