class DqDashboard extends HTMLElement {
  static getTemplate() {
    return `
      <h1>
        Overview
      </h1>
      <div>
        Total: {{Overview.countPassed}} / {{Overview.countTotal}}
      </div>
      <div>
        Plausibility: {{Overview.countPassedPlausibility}} / {{Overview.countTotalPlausibility}}
      </div>
      <div>
        Completeness:  {{Overview.countPassedCompleteness}} / {{Overview.countTotalCompleteness}}
      </div>
      <div>
        Conformance: {{Overview.countPassedConformance}} /  {{Overview.countTotalConformance}}
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