class DqMetadataRenderer extends HTMLElement {
    static getTemplate() {
        return `   
          <h2>
          Data Source Metadata
          </h2>            
          <div>{{this.CDM_SOURCE_NAME}}</div>
          <div>{{this.SOURCE_DESCRIPTION}}</div>          
          <div>Licensed to: {{this.CDM_HOLDER}}</div>                    
          <div>Source Released: {{this.SOURCE_RELEASE_DATE}}</div>          
          <div>CDM Released: {{this.CDM_RELEASE_DATE}}</div>          
          <div>CDM Version: {{this.CDM_VERSION}}</div>          
          <div>Vocabulary Version: {{this.VOCABULARY_VERSION}}</div>          
          <div>Source Documentation: {{this.SOURCE_DOCUMENTATION_REFERENCE}}</div>          
          <div>ETL Reference: {{this.CDM_ETL_REFERENCE}}</div>                    
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

        const hbTemplate = Handlebars.compile(DqMetadataRenderer.getTemplate());
        const html = hbTemplate(this.results);
        this.root.innerHTML = html;
    }
}

customElements.define('dq-metadata', DqMetadataRenderer);