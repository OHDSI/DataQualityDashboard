package com.arcadia.DataQualityDashboard.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.util.List;
import java.util.Objects;

import static javax.persistence.CascadeType.PERSIST;
import static javax.persistence.FetchType.LAZY;
import static javax.persistence.GenerationType.SEQUENCE;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity(name = "data_quality_scans")
public class DataQualityScan {
    @Id
    @SequenceGenerator(name = "data_quality_scan_id_sequence", sequenceName = "data_quality_scan_id_sequence")
    @GeneratedValue(strategy = SEQUENCE, generator = "data_quality_scan_id_sequence")
    private Long id;

    @Column(nullable = false)
    private String username;

    @Column(nullable = false)
    private String project;

    @Column(name = "status_code", nullable = false)
    private Integer statusCode;

    @Column(name = "status_name", nullable = false, length = 25)
    private String statusName;

    @JsonIgnore
    @OneToOne(cascade = PERSIST, mappedBy = "dataQualityScan", fetch = LAZY, orphanRemoval = true)
    private DbSettings dbSettings;

    @JsonIgnore
    @OneToMany(mappedBy = "dataQualityScan", fetch = LAZY, orphanRemoval = true)
    private List<DataQualityLog> logs;

    @JsonIgnore
    @OneToOne(mappedBy = "dataQualityScan", fetch = LAZY, orphanRemoval = true)
    private DataQualityResult result;

    public void setStatus(ScanStatus status) {
        this.statusCode = status.getCode();
        this.statusName = status.getName();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        DataQualityScan that = (DataQualityScan) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
