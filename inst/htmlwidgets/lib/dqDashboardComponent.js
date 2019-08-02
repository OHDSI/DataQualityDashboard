class DqDashboard extends HTMLElement {
  static getTemplate() {
    return `
      <h2>
        Data Quality Check Summary
      </h2>
      <div>
        Total: {{countPassed}} / {{countTotal}}
      </div>
      <div>
        Plausibility: {{countPassedPlausibility}} / {{countTotalPlausibility}}
      </div>
      <div>
        Completeness:  {{countPassedCompleteness}} / {{countTotalCompleteness}}
      </div>
      <div>
        Conformance: {{countPassedConformance}} /  {{countTotalConformance}}
      </div>
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
    if (!this.results)
      return;

    const hbTemplate = Handlebars.compile(DqDashboard.getTemplate());
    const html = hbTemplate(this.results);
    this.root.innerHTML = html;
  }
}

customElements.define('dq-dashboard', DqDashboard);