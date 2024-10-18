-- How many people choose seats in the Categories(Economy, Comfort and Business). Achieve this by joining multiple tables
SELECT COUNT(*),
st.fare_conditions
FROM boarding_passes bp
INNER JOIN flights fl
ON bp.flight_id = fl.flight_id
INNER JOIN seats st
ON st.seat_no = bp.seat_no AND fl.aircraft_code = st.aircraft_code
GROUP BY st.fare_conditions
ORDER BY COUNT(*) DESC;

-- Find out what the popular seats are
SELECT 
bp.seat_no,
COUNT(*)
FROM boarding_passes bp
LEFT JOIN ticket_flights tf
ON bp.ticket_no = tf.ticket_no AND bp.flight_id = tf.flight_id
GROUP BY seat_no
ORDER BY COUNT(*) DESC;

-- Find the average amount of the individual seats
SELECT seat_no,
AVG(amount)
FROM ticket_flights tf
LEFT JOIN boarding_passes bp
ON tf.ticket_no = bp.ticket_no AND tf.flight_id = bp.flight_id
GROUP BY seat_no
ORDER BY AVG(amount) DESC;

-- Create a list of all passenger names and their flight details
SELECT passenger_name,
scheduled_departure,
scheduled_arrival,
departure_airport,
arrival_airport,
status,
fare_conditions,
amount
FROM boarding_passes bp
LEFT JOIN ticket_flights tf
ON bp.ticket_no = tf.ticket_no AND bp.flight_id = tf.flight_id
LEFT JOIN tickets tk
ON tf.ticket_no = tk.ticket_no
LEFT JOIN flights fl 
ON tf. flight_id = fl.flight_id;




