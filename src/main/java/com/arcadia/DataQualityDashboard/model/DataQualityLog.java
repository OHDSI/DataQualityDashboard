package com.arcadia.DataQualityDashboard.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.sql.Timestamp;
import java.util.Objects;

import static javax.persistence.FetchType.LAZY;
import static javax.persistence.GenerationType.IDENTITY;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity(name = "data_quality_logs")
public class DataQualityLog {
    @Id
    @GeneratedValue(strategy = IDENTITY)
    private Long id;

    @Column(nullable = false, length = 1000)
    private String message;

    @Column(nullable = false)
    private Timestamp time;

    @Column(name = "status_code", nullable = false)
    private Integer statusCode;

    @Column(name = "status_name", nullable = false, length = 25)
    private String statusName;

    @Column(name = "percent", nullable = false)
    private Integer percent;

    @JsonIgnore
    @ManyToOne(optional = false, fetch = LAZY)
    @JoinColumn(name = "scan_id", referencedColumnName = "id")
    private DataQualityScan dataQualityScan;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        DataQualityLog that = (DataQualityLog) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
