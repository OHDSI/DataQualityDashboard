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
            padding: 3px;
        }

        td:empty, th:empty {
          border:0;
          background:transparent;
        }
    </style>

    <h2>Overall Assessment: {{Total.Total.PercentPassing}}</h2>
    <table>
        <thead>
            <tr>
                <td></td>
                <td colspan="3">Verification</td>
                <td colspan="3">Validation</td>
                <td colspan="3">Total</td>
            </tr>
            <tr>
                <td></td>
                <td>Passing</td>
                <td>Total</td>
                <td>% Passing</td>
                <td>Passing</td>
                <td>Total</td>
                <td>% Passing</td>
                <td>Passing</td>
                <td>Total</td>
                <td>% Passing</td>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>
                    Plausibility
                </td>
                <td>{{Verification.Plausibility.Passing}}</td>
                <td>{{Verification.Plausibility.Total}}</td>
                <td>{{Verification.Plausibility.PercentPassing}}</td>
                <td>{{Validation.Plausibility.Passing}}</td>
                <td>{{Validation.Plausibility.Total}}</td>
                <td>{{Validation.Plausibility.PercentPassing}}</td>
                <td>{{Total.Plausibility.Passing}}</td>
                <td>{{Total.Plausibility.Total}}</td>
                <td>{{Total.Plausibility.PercentPassing}}</td>
            </tr>
            <tr>
                <td>Conformance</td>
                <td>{{Verification.Conformance.Passing}}</td>
                <td>{{Verification.Conformance.Total}}</td>
                <td>{{Verification.Conformance.PercentPassing}}</td>
                <td>{{Validation.Conformance.Passing}}</td>
                <td>{{Validation.Conformance.Total}}</td>
                <td>{{Validation.Conformance.PercentPassing}}</td>
                <td>{{Total.Conformance.Passing}}</td>
                <td>{{Total.Conformance.Total}}</td>
                <td>{{Total.Conformance.PercentPassing}}</td>
            </tr>
            <tr>
                <td>Completeness</td>
                <td>{{Verification.Completeness.Passing}}</td>
                <td>{{Verification.Completeness.Total}}</td>
                <td>{{Verification.Completeness.PercentPassing}}</td>
                <td>{{Validation.Completeness.Passing}}</td>
                <td>{{Validation.Completeness.Total}}</td>
                <td>{{Validation.Completeness.PercentPassing}}</td>
                <td>{{Total.Completeness.Passing}}</td>
                <td>{{Total.Completeness.Total}}</td>
                <td>{{Total.Completeness.PercentPassing}}</td>
            </tr>
            <tr>
                <td>Total</td>
                <td>{{Verification.Total.Passing}}</td>
                <td>{{Verification.Total.Total}}</td>
                <td>{{Verification.Total.PercentPassing}}</td>
                <td>{{Validation.Total.Passing}}</td>
                <td>{{Validation.Total.Total}}</td>
                <td>{{Validation.Total.PercentPassing}}</td>
                <td>{{Total.Total.Passing}}</td>
                <td>{{Total.Total.Total}}</td>
                <td>{{Total.Total.PercentPassing}}</td>
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
    const VerificationPlausibilityPassing = this.results.filter(
      c => c.FAILED == 0 &&
        c.CONTEXT == "Verification"
        && c.CATEGORY == "Plausibility"
    ).length;

    const VerificationPlausibilityTotal = this.results.filter(
      c => c.CONTEXT == "Verification"
        && c.CATEGORY == "Plausibility"
    ).length;

    const VerificationPlausibilityPercentPassing = VerificationPlausibilityTotal == 0 ? "-" : Math.round(VerificationPlausibilityPassing / VerificationPlausibilityTotal * 100) + "%";

    // Verification Conformance
    const VerificationConformancePassing = this.results.filter(
      c => c.FAILED == 0 &&
        c.CONTEXT == "Verification"
        && c.CATEGORY == "Conformance"
    ).length;

    const VerificationConformanceTotal = this.results.filter(
      c => c.CONTEXT == "Verification"
        && c.CATEGORY == "Conformance"
    ).length;

    const VerificationConformancePercentPassing = VerificationConformanceTotal == 0 ? "-" : Math.round(VerificationConformancePassing / VerificationConformanceTotal * 100) + "%";

    // Verification Completeness
    const VerificationCompletenessPassing = this.results.filter(
      c => c.FAILED == 0 &&
        c.CONTEXT == "Verification"
        && c.CATEGORY == "Completeness"
    ).length;

    const VerificationCompletenessTotal = this.results.filter(
      c => c.CONTEXT == "Verification"
        && c.CATEGORY == "Completeness"
    ).length;

    const VerificationCompletenessPercentPassing = VerificationCompletenessTotal == 0 ? "-" : Math.round(VerificationCompletenessPassing / VerificationCompletenessTotal * 100) + "%";

    // Verification Totals
    const VerificationPassing = this.results.filter(
      c => c.FAILED == 0 &&
        c.CONTEXT == "Verification"
    ).length;

    const VerificationTotal = this.results.filter(
      c => c.CONTEXT == "Verification"
    ).length;

    const VerificationPercentPassing = VerificationTotal == 0 ? "-" : Math.round(VerificationPassing / VerificationTotal * 100) + "%";

    // Validation Plausibility
    const ValidationPlausibilityPassing = this.results.filter(
      c => c.FAILED == 0 &&
        c.CONTEXT == "Validation"
        && c.CATEGORY == "Plausibility"
    ).length;

    const ValidationPlausibilityTotal = this.results.filter(
      c => c.CONTEXT == "Validation"
        && c.CATEGORY == "Plausibility"
    ).length;

    const ValidationPlausibilityPercentPassing = ValidationPlausibilityTotal == 0 ? "-" : Math.round(ValidationPlausibilityPassing / ValidationPlausibilityTotal * 100) + "%";

    // Validation Conformance
    const ValidationConformancePassing = this.results.filter(
      c => c.FAILED == 0 &&
        c.CONTEXT == "Validation"
        && c.CATEGORY == "Conformance"
    ).length;

    const ValidationConformanceTotal = this.results.filter(
      c => c.CONTEXT == "Validation"
        && c.CATEGORY == "Conformance"
    ).length;

    const ValidationConformancePercentPassing = ValidationConformanceTotal == 0 ? "-" : Math.round(ValidationConformancePassing / ValidationConformanceTotal * 100) + "%";

    // Validation Completeness
    const ValidationCompletenessPassing = this.results.filter(
      c => c.FAILED == 0 &&
        c.CONTEXT == "Validation"
        && c.CATEGORY == "Completeness"
    ).length;

    const ValidationCompletenessTotal = this.results.filter(
      c => c.CONTEXT == "Validation"
        && c.CATEGORY == "Completeness"
    ).length;

    const ValidationCompletenessPercentPassing = ValidationCompletenessTotal == 0 ? "-" : Math.round(ValidationCompletenessPassing / ValidationCompletenessTotal * 100) + "%";

    // Validation
    const ValidationPassing = this.results.filter(
      c => c.FAILED == 0 &&
        c.CONTEXT == "Validation"
    ).length;

    const ValidationTotal = this.results.filter(
      c => c.CONTEXT == "Validation"
    ).length;

    const ValidationPercentPassing = ValidationTotal == 0 ? "-" : Math.round(ValidationPassing / ValidationTotal * 100) + "%";

    // Plausibility
    const PlausibilityPassing = this.results.filter(
      c => c.FAILED == 0 &&
        c.CATEGORY == "Plausibility"
    ).length;

    const PlausibilityTotal = this.results.filter(
      c => c.CATEGORY == "Plausibility"
    ).length;

    const PlausibilityPercentPassing = PlausibilityTotal == 0 ? "-" : Math.round(PlausibilityPassing / PlausibilityTotal * 100) + "%";

    // Conformance
    const ConformancePassing = this.results.filter(
      c => c.FAILED == 0
        && c.CATEGORY == "Conformance"
    ).length;

    const ConformanceTotal = this.results.filter(
      c => c.CATEGORY == "Conformance"
    ).length;

    const ConformancePercentPassing = ConformanceTotal == 0 ? "-" : Math.round(ConformancePassing / ConformanceTotal * 100) + "%";

    // Completeness
    const CompletenessPassing = this.results.filter(
      c => c.FAILED == 0
        && c.CATEGORY == "Completeness"
    ).length;

    const CompletenessTotal = this.results.filter(
      c => c.CATEGORY == "Completeness"
    ).length;

    const CompletenessPercentPassing = CompletenessTotal == 0 ? "-" : Math.round(CompletenessPassing / CompletenessTotal * 100) + "%";

    // All
    const AllPassing = this.results.filter(
      c => c.FAILED == 0
    ).length;

    const AllTotal = this.results.length;

    const AllPercentPassing = AllTotal == 0 ? "-" : Math.round(AllPassing / AllTotal * 100) + "%";

    const derivedResults = {
      "Verification": {
        "Plausibility": {
          "Passing": VerificationPlausibilityPassing,
          "Total": VerificationPlausibilityTotal,
          "PercentPassing": VerificationPlausibilityPercentPassing
        },
        "Conformance": {
          "Passing": VerificationConformancePassing,
          "Total": VerificationConformanceTotal,
          "PercentPassing": VerificationConformancePercentPassing
        },
        "Completeness": {
          "Passing": VerificationCompletenessPassing,
          "Total": VerificationCompletenessTotal,
          "PercentPassing": VerificationCompletenessPercentPassing
        },
        "Total": {
          "Passing": VerificationPassing,
          "Total": VerificationTotal,
          "PercentPassing": VerificationPercentPassing
        }
      },
      "Validation": {
        "Plausibility": {
          "Passing": ValidationPlausibilityPassing,
          "Total": ValidationPlausibilityTotal,
          "PercentPassing": ValidationPlausibilityPercentPassing
        },
        "Conformance": {
          "Passing": ValidationConformancePassing,
          "Total": ValidationConformanceTotal,
          "PercentPassing": ValidationConformancePercentPassing
        },
        "Completeness": {
          "Passing": ValidationCompletenessPassing,
          "Total": ValidationCompletenessTotal,
          "PercentPassing": ValidationCompletenessPercentPassing
        },
        "Total": {
          "Passing": ValidationPassing,
          "Total": ValidationTotal,
          "PercentPassing": ValidationPercentPassing
        }
      },
      "Total": {
        "Plausibility": {
          "Passing": PlausibilityPassing,
          "Total": PlausibilityTotal,
          "PercentPassing": PlausibilityPercentPassing
        },
        "Conformance": {
          "Passing": ConformancePassing,
          "Total": ConformanceTotal,
          "PercentPassing": ConformancePercentPassing
        },
        "Completeness": {
          "Passing": CompletenessPassing,
          "Total": CompletenessTotal,
          "PercentPassing": CompletenessPercentPassing
        },
        "Total": {
          "Passing": AllPassing,
          "Total": AllTotal,
          "PercentPassing": AllPercentPassing
        }
      }
    }

    const hbTemplate = Handlebars.compile(DqDashboard.getTemplate());
    const html = hbTemplate(derivedResults);
    this.root.innerHTML = html;
  }
}

customElements.define('dq-dashboard', DqDashboard);