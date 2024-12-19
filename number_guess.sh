#!/bin/bash

# PSQL command for interacting with the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read username

# Check if the user exists in the database
user_info=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username = '$username';")

if [[ -z $user_info ]]; then
    # If user doesn't exist, it's their first time
    echo "Welcome, $username! It looks like this is your first time here."
    games_played=0
    best_game="N/A"
else
    # Extract data from the query
    games_played=$(echo $user_info | cut -d '|' -f 2)
    best_game=$(echo $user_info | cut -d '|' -f 3)
    echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

# Generate a random number between 1 and 1000
secret_number=$((RANDOM % 1000 + 1))
echo "Guess the secret number between 1 and 1000:"
guess_count=0

# Loop to get the user's guesses until the correct number is guessed
while true; do
    read guess

    # Check if the input is an integer
    if ! [[ "$guess" =~ ^[0-9]+$ ]]; then
        echo "That is not an integer, guess again:"
        continue
    fi

    ((guess_count++))

    # Compare guess with secret number
    if ((guess > secret_number)); then
        echo "It's lower than that, guess again:"
    elif ((guess < secret_number)); then
        echo "It's higher than that, guess again:"
    else
        # Correct guess, exit the loop
        echo "You guessed it in $guess_count tries. The secret number was $secret_number. Nice job!"
        break
    fi
done

# Update game stats in the database
if [[ -z $user_info ]]; then
    # Insert new user
    $PSQL "INSERT INTO users (username, games_played, best_game) VALUES ('$username', 1, $guess_count);"
else
    # Update existing user
    new_games_played=$((games_played + 1))
    if [[ -z $best_game || $guess_count -lt $best_game ]]; then
        # Update best_game if this game was better
        $PSQL "UPDATE users SET games_played = $new_games_played, best_game = $guess_count WHERE username = '$username';"
    else
        $PSQL "UPDATE users SET games_played = $new_games_played WHERE username = '$username';"
    fi
fi
