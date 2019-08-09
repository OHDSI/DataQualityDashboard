class DqCheckRenderer extends HTMLElement {
    static getTemplate() {
        return `
        {{#each checks}}
          <div><b>Check Details</b></div>        
          <div>{{this.CHECK_NAME}} - {{this.CHECK_LEVEL}} - {{this.CDM_TABLE}} - {{this.CDM_FIELD}}</div>
          <div><b>Check Description</b></div>
          <div>{{this.CHECK_DESCRIPTION}}</div>
          <div><b>Violated Rows</b></div>
          <div>{{this.NUM_VIOLATED_ROWS}}</div>
          <div><b>Proportion Violated Rows</b></div>
          <div>{{this.PCT_VIOLATED_ROWS}}</div>
          <div><b>Query</b></div>          
          <div><pre>{{this.QUERY_TEXT}}</pre></div>
          <div><b>Errror</b></div>
          <div>{{this.ERROR}}</div>     
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