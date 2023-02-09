class DqMetadataRenderer extends HTMLElement {
    static getTemplate() {
        return `   
          <h2>
          Data Source Metadata
          </h2>            
          <div>{{this.cdmSourceName}}</div>
          <div>{{this.sourceDescription}}</div>          
          <div>Licensed to: {{this.cdmHolder}}</div>                    
          <div>Source Released: {{this.sourceReleaseDate}}</div>          
          <div>CDM Released: {{this.cdmReleaseDate}}</div>          
          <div>CDM Version: {{this.cdmVersion}}</div>          
          <div>Vocabulary Version: {{this.vocabularyVersion}}</div>          
          <div>Source Documentation: {{this.sourceDocumentationReference}}</div>          
          <div>ETL Reference: {{this.cdmEtlReference}}</div>                    
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