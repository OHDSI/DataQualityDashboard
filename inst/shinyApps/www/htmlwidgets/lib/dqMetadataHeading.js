class DqMetadataHeadingRenderer extends HTMLElement {
    static getTemplate() {
        return `   
          <style>
          h1,
          h2,
          h3,
          h4,
          h5,
          h6 {
            font-family: 'Saira Extra Condensed', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
            font-weight: 700;
            text-transform: uppercase;
            color: #222222;
          }          
          </style>
          <h1>{{CDM_SOURCE_NAME}}</h1>
          <div class="text-muted">
            Results generated at {{startTimestamp}} in {{executionTime}}
          </div>
          <br>
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