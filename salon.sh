#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -X -q -A -t -v ON_ERROR_STOP=1"

get_services() {
  $PSQL -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

printf "\n~~~~~ MY SALON ~~~~~\n\n"
printf "Welcome to My Salon, how can I help you?\n\n"
get_services

while true; do
  read SERVICE_ID_SELECTED || exit 0
  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$($PSQL -v service_id="$SERVICE_ID_SELECTED" <<< "SELECT name FROM services WHERE service_id = :'service_id';")
  else
    SERVICE_NAME=""
  fi

  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  printf "\nI could not find that service. What would you like today?\n"
  get_services
done

printf "\nWhat's your phone number?\n"
read CUSTOMER_PHONE || exit 0

CUSTOMER_ID=$($PSQL -v phone="$CUSTOMER_PHONE" <<< "SELECT customer_id FROM customers WHERE phone = :'phone';")
if [[ -z "$CUSTOMER_ID" ]]; then
  printf "\nI don't have a record for that phone number, what's your name?\n"
  read CUSTOMER_NAME || exit 0
  CUSTOMER_ID=$($PSQL -v phone="$CUSTOMER_PHONE" -v name="$CUSTOMER_NAME" <<< "INSERT INTO customers (phone, name) VALUES (:'phone', :'name') RETURNING customer_id;")
else
  CUSTOMER_NAME=$($PSQL -v phone="$CUSTOMER_PHONE" <<< "SELECT name FROM customers WHERE phone = :'phone';")
fi

printf "\nWhat time would you like your %s, %s?\n" "$SERVICE_NAME" "$CUSTOMER_NAME"
read SERVICE_TIME || exit 0

$PSQL -v customer_id="$CUSTOMER_ID" -v service_id="$SERVICE_ID_SELECTED" -v service_time="$SERVICE_TIME" <<< "INSERT INTO appointments (customer_id, service_id, time) VALUES (:'customer_id', :'service_id', :'service_time');" >/dev/null

printf "\nI have put you down for a %s at %s, %s.\n" "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
