class DqCheckRenderer extends HTMLElement {
    static getTemplate() {
        return `
        {{#each checks}}
          <div><b>Check Details</b></div>        
          <div>{{this.checkName}} - {{this.checkLevel}} - {{this.CDM_TABLE}} - {{this.CDM_FIELD}}</div>
          <div><b>Check Description</b></div>
          <div>{{this.checkDescription}}</div>
          <div><b>Violated Rows</b></div>
          <div>{{this.numViolatedRows}}</div>
          <div><b>Proportion Violated Rows</b></div>
          <div>{{this.pctViolatedRows}}</div>
          <div><b>Query</b></div>          
          <div><pre>{{this.queryText}}</pre></div>
          <div><b>Errror</b></div>
          <div>{{this.error}}</div>     
          <hr></hr>
        {{/each}}
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

        const hbTemplate = Handlebars.compile(DqCheckRenderer.getTemplate());
        const html = hbTemplate(this.results);
        this.root.innerHTML = html;
    }
}

customElements.define('dq-checks', DqCheckRenderer);