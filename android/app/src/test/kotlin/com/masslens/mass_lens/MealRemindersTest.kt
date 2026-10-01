package com.masslens.mass_lens

import java.util.Calendar
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MealRemindersTest {
    private fun at(hour: Int, minute: Int, dayOffset: Int = 0): Long =
        Calendar.getInstance().apply {
            set(2026, Calendar.SEPTEMBER, 17, hour, minute, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.DAY_OF_YEAR, dayOffset)
        }.timeInMillis

    @Test
    fun schedulesLaterToday() {
        assertEquals(at(12, 30), MealReminders.nextTriggerMillis(at(9, 0), 12, 30))
    }

    @Test
    fun schedulesTomorrowWhenTimeHasPassed() {
        assertEquals(at(12, 30, 1), MealReminders.nextTriggerMillis(at(12, 30), 12, 30))
        assertEquals(at(12, 30, 1), MealReminders.nextTriggerMillis(at(18, 0), 12, 30))
    }

    @Test
    fun skipsWhenAMealWasLoggedRecently() {
        val now = at(12, 30)
        assertTrue(MealReminders.shouldNotify(now, 0L))
        assertFalse(MealReminders.shouldNotify(now, at(11, 0)))
        assertTrue(MealReminders.shouldNotify(now, at(8, 0)))
        assertTrue(MealReminders.shouldNotify(now, at(13, 0)))
    }
}
