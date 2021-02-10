package com.arcadia.DataQualityDashboard.util;

import org.junit.jupiter.api.Test;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import static com.arcadia.DataQualityDashboard.util.CompareDate.getDateDiffInHours;
import static org.junit.jupiter.api.Assertions.assertEquals;

class CompareDateTest {

    @Test
    void compareDate() throws ParseException {
        SimpleDateFormat sdf = new SimpleDateFormat("MM/dd/yyyy", Locale.ENGLISH);
        Date firstDate = sdf.parse("01/02/2021");
        Date secondDate = sdf.parse("01/01/2021");

        long diffInHours = getDateDiffInHours(firstDate, secondDate);

        assertEquals(24, diffInHours);
    }
}
