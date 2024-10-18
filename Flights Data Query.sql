-- ##############################
-- ## FLIGHT STATUS SUMMARY
-- ##############################
-- This query summarizes the count of flights by their current status (e.g., On Time, Delayed, Cancelled).
SELECT 
    FL.STATUS,
    COUNT(*) AS FLIGHT_COUNT
FROM FLIGHTS FL
GROUP BY FL.STATUS;

-- ##############################
-- ## PASSENGER COUNT BY AIRCRAFT TYPE
-- ##############################
-- This query counts the number of passengers who flew on each type of aircraft.
SELECT 
    FL.AIRCRAFT_CODE,
    COUNT(BP.PASSENGER_NAME) AS PASSENGER_COUNT
FROM BOARDING_PASSES BP
LEFT JOIN FLIGHTS FL ON BP.FLIGHT_ID = FL.FLIGHT_ID
GROUP BY FL.AIRCRAFT_CODE
ORDER BY PASSENGER_COUNT DESC;

-- ##############################
-- ## FLIGHT CANCELLATION RATE
-- ##############################
-- This query calculates the cancellation rate of flights by comparing cancelled flights to total flights.
SELECT 
    COUNT(CASE WHEN FL.STATUS = 'Cancelled' THEN 1 END) AS CANCELLED_FLIGHTS,
    COUNT(*) AS TOTAL_FLIGHTS,
    (COUNT(CASE WHEN FL.STATUS = 'Cancelled' THEN 1 END) * 100.0 / COUNT(*)) AS CANCELLATION_RATE
FROM FLIGHTS FL;

-- ##############################
-- ## AVERAGE TIME BETWEEN DEPARTURE AND ARRIVAL
-- ##############################
-- This query calculates the average time between scheduled departure and scheduled arrival across all flights.
SELECT 
    AVG(TIMESTAMPDIFF(MINUTE, FL.SCHEDULED_DEPARTURE, FL.SCHEDULED_ARRIVAL)) AS AVG_TIME_MINUTES
FROM FLIGHTS FL;

-- ##############################
-- ## FREQUENCY OF FLIGHT PER ROUTE
-- ##############################
-- This query counts how many flights operate on each route (from departure to arrival airport).
SELECT 
    FL.DEPARTURE_AIRPORT,
    FL.ARRIVAL_AIRPORT,
    COUNT(*) AS FLIGHT_FREQUENCY
FROM FLIGHTS FL
GROUP BY FL.DEPARTURE_AIRPORT, FL.ARRIVAL_AIRPORT
ORDER BY FLIGHT_FREQUENCY DESC;

-- ##############################
-- ## AVERAGE REVENUE PER PASSENGER
-- ##############################
-- This query calculates the average revenue generated per passenger across all flights.
SELECT 
    SUM(TK.AMOUNT) / COUNT(BP.PASSENGER_NAME) AS AVG_REVENUE_PER_PASSENGER
FROM BOARDING_PASSES BP
LEFT JOIN TICKET_FLIGHTS TF ON BP.TICKET_NO = TF.TICKET_NO AND BP.FLIGHT_ID = TF.FLIGHT_ID
LEFT JOIN TICKETS TK ON TF.TICKET_NO = TK.TICKET_NO;

-- ##############################
-- ## TICKET SALES TREND BY MONTH
-- ##############################
-- This query shows the trend of ticket sales over each month.
SELECT 
    DATE_FORMAT(TF.SALE_DATE, '%Y-%m') AS SALE_MONTH,
    COUNT(TF.TICKET_NO) AS TICKET_SALES
FROM TICKET_FLIGHTS TF
GROUP BY SALE_MONTH
ORDER BY SALE_MONTH;

-- ##############################
-- ## SEAT OCCUPANCY RATE BY FLIGHT
-- ##############################
-- This query calculates the occupancy rate for each flight based on the number of boarding passes issued.
SELECT 
    FL.FLIGHT_ID,
    COUNT(BP.PASSENGER_NAME) AS PASSENGER_COUNT,
    ST.CAPACITY,
    (COUNT(BP.PASSENGER_NAME) * 100.0 / ST.CAPACITY) AS OCCUPANCY_RATE
FROM FLIGHTS FL
LEFT JOIN BOARDING_PASSES BP ON FL.FLIGHT_ID = BP.FLIGHT_ID
LEFT JOIN SEATS ST ON FL.AIRCRAFT_CODE = ST.AIRCRAFT_CODE
GROUP BY FL.FLIGHT_ID, ST.CAPACITY
ORDER BY OCCUPANCY_RATE DESC;

-- ##############################
-- ## MOST COMMON FLIGHT ORIGINS
-- ##############################
-- This query identifies the most common departure airports by counting the number of flights from each airport.
SELECT 
    FL.DEPARTURE_AIRPORT,
    COUNT(*) AS FLIGHT_COUNT
FROM FLIGHTS FL
GROUP BY FL.DEPARTURE_AIRPORT
ORDER BY FLIGHT_COUNT DESC;
