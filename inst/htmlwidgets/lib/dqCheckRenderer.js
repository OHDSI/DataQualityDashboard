class DqCheckRenderer extends HTMLElement {
    static getTemplate() {
        return `
        {{#each checks}}
          <div>{{this.QUERY_TEXT}}</div>
          <div>{{this.ERROR}}</div>     
          <div>{{this.CHECK_ID}}</div>               
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