const RESULTS_ATTR = 'data-results';

class DqDashboard extends HTMLElement {

  static getTemplate() {
    return `
      <h1>
        Overview
      </h1>
      <h2>
        Checks
      </h2>
      <div>
        Passed: {{Overview.passed}} / {{Overview.total}}
      </div>
    `;
  }

  connectedCallback() {
    this.root = this.attachShadow({ mode: 'open' });
    this.render();
  }

  static get observedAttributes() {
    return [RESULTS_ATTR];
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (this.root && oldValue !== newValue) {
      this.render();
    }
  }

  get results() {
    return JSON.parse(this.getAttribute(RESULTS_ATTR));
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