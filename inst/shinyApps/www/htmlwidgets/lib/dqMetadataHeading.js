class DqMetadataHeadingRenderer extends HTMLElement {
    static getTemplate() {
        return `   
          <h2>{{CDM_SOURCE_NAME}}</h2>
          <div>
            Results generated at {{startTimestamp}} in {{executionTime}}
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
        const derivedResults = {
            "startTimestamp": this.results.startTimestamp,
            "executionTime": this.results.executionTime,
            "CDM_SOURCE_NAME": this.results.Metadata[0].CDM_SOURCE_NAME,
            "SOURCE_DESCRIPTION": this.results.Metadata[0].SOURCE_DESCRIPTION
        }
        const hbTemplate = Handlebars.compile(DqMetadataHeadingRenderer.getTemplate());
        const html = hbTemplate(derivedResults);
        this.root.innerHTML = html;
    }
}

customElements.define('dq-metadata-heading', DqMetadataHeadingRenderer);