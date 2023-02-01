package com.arcadia.DataQualityDashboard.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import javax.validation.constraints.NotNull;
import java.util.Objects;

import static javax.persistence.FetchType.LAZY;
import static javax.persistence.GenerationType.SEQUENCE;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity(name = "db_settings")
public class DbSettings {
    @Id
    @SequenceGenerator(name = "db_setting_id_sequence", sequenceName = "db_setting_id_sequence")
    @GeneratedValue(strategy = SEQUENCE, generator = "db_setting_id_sequence")
    private Long id;

    @NotNull
    @Column(nullable = false)
    private String dbType;

    @NotNull
    @Column(nullable = false)
    private String server;

    @NotNull
    @Column(nullable = false)
    private Integer port;

    @NotNull
    @Column(name = "username", nullable = false)
    private String user;

    @NotNull
    @Transient
    private String password;

    @NotNull
    @Column(name = "database_name", nullable = false)
    private String database;

    @Column(name = "schema_name")
    private String schema;
    
    private String httppath;

    @JsonIgnore
    @OneToOne(fetch = LAZY, optional = false)
    @JoinColumn(name = "scan_id", referencedColumnName = "id")
    private DataQualityScan dataQualityScan;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        DbSettings that = (DbSettings) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
